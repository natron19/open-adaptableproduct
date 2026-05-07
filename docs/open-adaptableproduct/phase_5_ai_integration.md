# Phase 5 — AI Integration

**Goal:** The "Surface Assumptions" button calls Gemini, parses the JSON response into Assumption rows, and renders the matrix table. Error states (parse failure, budget, timeout, gatekeeper) are handled gracefully.

**Prerequisites:** Phase 4 complete. Strategy product CRUD working in browser. `GEMINI_API_KEY` set in `.env`.

**Spec reference:** `docs/open-adaptableproduct/AdaptableProduct_Demo_Spec_v1.md` §5, §7, §8

---

## Context

### How GeminiService works

Never call the Gemini API directly. Always use `GeminiService.generate`:

```ruby
result = GeminiService.generate(
  template:  "adaptableproduct_assumptions_v1",
  variables: { product_name: ..., target_customer: ..., strategy: ..., primary_goal: ... }
)
```

This method:
1. Passes input through `AiGatekeeper` (length, injection patterns, profanity)
2. Checks `AiBudgetChecker` (daily cap per user from `AI_CALLS_PER_USER_PER_DAY`)
3. Writes a `pending` `LlmRequest` row
4. Calls the Gemini API with the template's model, tokens, temperature
5. Updates `LlmRequest` to `success` / `timeout` / `error`
6. Returns the raw response string

Errors raised by `GeminiService`:
- `GeminiService::GatekeeperError` — input blocked
- `GeminiService::BudgetExceededError` — daily cap reached
- `GeminiService::TimeoutError` — Gemini took too long
- `GeminiService::GeminiError` — generic Gemini failure (superclass of all above)

The boilerplate's `shared/_ai_error.html.erb` partial renders all four gracefully. Use it.

### Working Gemini models

Use `gemini-2.5-flash`. Do NOT use `gemini-2.0-flash` or `1.5-*` models — they return 404 on v1beta for new API keys.

### System prompt note

`GeminiService` prepends the system prompt to the user message — the v1beta API does not support a separate `system_instruction` field. The template stores the system prompt in `system_prompt`, which `GeminiService` handles automatically.

---

## Task 1: Seed the AiTemplate

Add to `db/seeds.rb` (use `find_or_create_by!` for idempotency):

```ruby
AiTemplate.find_or_create_by!(name: "adaptableproduct_assumptions_v1") do |t|
  t.description = "Surfaces 8 to 12 ranked, falsifiable assumptions a product strategy depends on, paired with risk, category, and a cheap-first experiment."
  t.model = "gemini-2.5-flash"
  t.max_output_tokens = 2500
  t.temperature = 0.4
  t.system_prompt = <<~PROMPT.strip
    You are a senior product strategist working with the user on the
    Assumption Challenge step of the 9-Step Adaptable Product Framework.
    Your job is to read the user's product strategy and return the
    8 to 12 most consequential assumptions the strategy depends on.

    For each assumption, you must:

    1. State the assumption as a single, falsifiable claim. Not a hope,
       not a generality. A claim that could in principle be proven wrong
       by an experiment, customer interview, or market signal.
    2. Rate the assumption's confidence (1 to 5) based on what is observable
       in the strategy and target customer description. 1 means the strategy
       barely supports this assumption; 5 means it is heavily evidenced
       inside the strategy itself.
    3. Rate the risk (low, medium, high) based on what breaks if the
       assumption is wrong. High = the strategy itself collapses. Medium =
       the strategy needs material rework. Low = a tactic changes.
    4. Categorize the assumption as one of: customer, market, capability,
       economics, competitive, regulatory.
    5. Suggest one specific experiment that could test the assumption.
       Order assumptions so the cheapest, most informative experiments
       come first.

    Return assumptions ranked by leverage: the assumption whose disconfirmation
    would most reshape the strategy goes first.

    You must return ONLY a JSON object with this exact shape, no preamble,
    no markdown fence, no explanation:

    {
      "assumptions": [
        {
          "statement": "string, one sentence, falsifiable claim",
          "confidence_ai": 1-5,
          "risk": "low" | "medium" | "high",
          "category": "customer" | "market" | "capability" | "economics" | "competitive" | "regulatory",
          "experiment": "string, one specific test, 1-2 sentences"
        }
      ]
    }

    The "assumptions" array must have between 8 and 12 entries. No fewer, no more.
  PROMPT
  t.user_prompt_template = <<~PROMPT.strip
    Product name: {{product_name}}

    Target customer: {{target_customer}}

    Current strategy:
    {{strategy}}

    Primary goal this strategy is meant to advance:
    {{primary_goal}}

    Surface the 8 to 12 most consequential assumptions this strategy depends
    on. Return JSON only, conforming to the schema in your instructions.
  PROMPT
  t.notes = <<~NOTES.strip
    This template is the entire demo. Iterate here.

    Watch for:
    - Assumptions that are not falsifiable. Tighten with examples if this happens.
    - Categories drifting outside the six allowed values.
    - Generic experiments ("interview customers"). Tighten with specific examples in the system prompt.
    - Fewer than 8 or more than 12 assumptions. Lower temperature to 0.3 if this happens often.

    Known failure modes:
    - Strategies under 50 chars produce thin matrices. Form validation enforces 50+ chars.
    - Highly novel domains produce more "market" category assumptions — this reflects the strategy, not a bug.
  NOTES
end
```

Run `rails db:seed` and verify the template appears at `/admin/ai_templates`.

---

## Task 2: Implement `AssumptionMatricesController#create`

Replace the Phase 3 stub. Full implementation:

```ruby
def create
  @matrix = @strategy_product.assumption_matrices.create!(status: "pending")

  raw = GeminiService.generate(
    template:  "adaptableproduct_assumptions_v1",
    variables: {
      product_name:    @strategy_product.name,
      target_customer: @strategy_product.target_customer,
      strategy:        @strategy_product.strategy,
      primary_goal:    @strategy_product.primary_goal
    }
  )

  @matrix.update!(gemini_raw: raw, generated_at: Time.current)
  entries = parse_assumptions(raw)

  entries.each_with_index do |entry, i|
    @matrix.assumptions.create!(
      statement:    entry["statement"],
      confidence_ai: entry["confidence_ai"],
      risk:         entry["risk"],
      category:     entry["category"],
      experiment:   entry["experiment"],
      position:     i + 1
    )
  end

  @matrix.update!(status: "completed")
  redirect_to strategy_product_assumption_matrix_path(@strategy_product, @matrix)

rescue ParseError => e
  @matrix&.update(status: "failed", gemini_raw: e.raw)
  redirect_to strategy_product_assumption_matrix_path(@strategy_product, @matrix)

rescue GeminiService::BudgetExceededError
  @matrix&.update(status: "failed")
  render partial: "shared/ai_error", locals: { error_type: :budget_exceeded }

rescue GeminiService::GatekeeperError
  @matrix&.update(status: "failed")
  render partial: "shared/ai_error", locals: { error_type: :gatekeeper_blocked }

rescue GeminiService::TimeoutError
  @matrix&.update(status: "failed")
  render partial: "shared/ai_error", locals: { error_type: :timeout }

rescue GeminiService::GeminiError
  @matrix&.update(status: "failed")
  render partial: "shared/ai_error", locals: { error_type: :error }
end
```

### ParseError and `parse_assumptions` private method

```ruby
ParseError = Class.new(StandardError) do
  attr_reader :raw
  def initialize(msg, raw:) = super(msg).tap { @raw = raw }
end

def parse_assumptions(raw)
  stripped = raw.gsub(/\A```json\s*|\s*```\z/, "").strip
  parsed   = JSON.parse(stripped)
  entries  = parsed["assumptions"]

  unless entries.is_a?(Array) && entries.size.between?(8, 12)
    raise ParseError.new("Wrong number of assumptions: #{entries&.size}", raw: raw)
  end

  valid_risks       = Assumption::RISKS
  valid_categories  = Assumption::CATEGORIES
  required_keys     = %w[statement confidence_ai risk category experiment]

  entries.each do |entry|
    missing = required_keys - entry.keys
    raise ParseError.new("Missing keys: #{missing}", raw: raw) if missing.any?
    unless (1..5).cover?(entry["confidence_ai"].to_i)
      raise ParseError.new("confidence_ai out of range", raw: raw)
    end
    unless valid_risks.include?(entry["risk"])
      raise ParseError.new("Invalid risk: #{entry["risk"]}", raw: raw)
    end
    unless valid_categories.include?(entry["category"])
      raise ParseError.new("Invalid category: #{entry["category"]}", raw: raw)
    end
  end

  entries
rescue JSON::ParserError => e
  raise ParseError.new("JSON parse failed: #{e.message}", raw: raw)
end
```

### Rate limiting

Add to `AssumptionMatricesController`:

```ruby
rate_limit to: 10, within: 1.minute, only: :create, by: -> { current_user.id }
```

---

## Task 3: `AssumptionMatrices#show` handles failed state

In the `show` action, expose `@matrix.status` to the view. In `assumption_matrices/show.html.erb`, conditionally render the parse error partial:

```erb
<% if @matrix.status == "failed" %>
  <%= render "matrix_parse_error", strategy_product: @strategy_product, matrix: @matrix %>
<% elsif @matrix.status == "completed" %>
  <%= render "matrix_table", assumptions: @matrix.assumptions.order(:position) %>
<% else %>
  <p class="text-muted">This matrix is still generating…</p>
<% end %>
```

---

## Manual Checks

```
[ ] GEMINI_API_KEY set in .env
[ ] rails db:seed — adaptableproduct_assumptions_v1 template present at /admin/ai_templates
[ ] Sign in, create a product with FieldNote values, click "Surface Assumptions"
[ ] Spinner shows during the Gemini call (4–10 seconds typical)
[ ] Matrix renders with 8–12 assumption rows on success
[ ] "Show raw response" toggle reveals the JSON from Gemini
[ ] Admin /admin/llm_requests shows a new row with status "success"
[ ] Parse error test: in admin, temporarily break the JSON schema instruction in the template; re-run the call — parse error partial appears with raw response and retry button; restore the template
[ ] Gemini error test: temporarily set GEMINI_API_KEY to an invalid value; re-run — ai_error partial renders inline; restore the key
[ ] Admin /admin/ai_templates — edit the template, use the Test panel to verify the prompt fires and returns valid JSON
[ ] Rate limiting: attempting >10 Surface Assumptions in 1 minute returns an error response (use a loop in the browser console or curl)
```

---

## RSpec

Write `spec/requests/assumption_matrices_spec.rb`. Required coverage:

- `POST /products/:id/matrices` calls `GeminiService.generate` with the correct template name and all four variables (use the boilerplate's test double stub)
- Successful call creates one `AssumptionMatrix` with status `completed` and 8–12 `Assumption` rows
- `gemini_raw` on the matrix is set to the stubbed response string
- An `LlmRequest` record is created (the stub still writes the log row)
- A parse-failure response (stub returns malformed JSON) marks the matrix `failed` and renders the parse-error partial
- `GeminiService::BudgetExceededError` raised by stub renders the budget-exceeded partial and does not create a completed matrix
- `GeminiService::TimeoutError` renders the timeout partial
- A different signed-in user gets 404 when posting to another user's product's matrices path
- Unauthenticated request redirects to sign in

```bash
bundle exec rspec spec/requests/assumption_matrices_spec.rb
```

### Stub pattern (from boilerplate's `spec/support/gemini_test_double.rb`)

```ruby
# Valid 8-entry response stub
let(:valid_gemini_response) do
  { "assumptions" => Array.new(8) {
    { "statement" => "Users will pay $39/mo",
      "confidence_ai" => 3,
      "risk" => "high",
      "category" => "economics",
      "experiment" => "Test with 10 direct purchase links." }
  }}.to_json
end

before { allow(GeminiService).to receive(:generate).and_return(valid_gemini_response) }

# Parse-error stub
before { allow(GeminiService).to receive(:generate).and_return("not json at all") }

# Budget error stub
before { allow(GeminiService).to receive(:generate).and_raise(GeminiService::BudgetExceededError) }
```
