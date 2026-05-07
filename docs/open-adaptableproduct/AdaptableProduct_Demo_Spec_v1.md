# AdaptableProduct Demo - Spec Document

**Document Version:** 1.0
**Built On:** Open Demo Starter boilerplate v2.0
**License:** MIT
**Source Brief:** 32_AppBrief_AdaptableProduct_v1.md
**Production Counterpart:** AdaptableProduct (multi-tenant SaaS)

---

## 1. App Overview

**AdaptableProduct Demo** is a single-page open source Rails 8 app that lets a product leader describe their product strategy in four short fields and receive an **Assumption Matrix**: an AI-generated, ranked list of 8 to 12 falsifiable assumptions the strategy depends on, each paired with a risk rating, a category, and a suggested experiment.

The demo isolates one move from the 9-Step Adaptable Product Framework: **Step 3, Assumption Challenge**. This is the single most productive step a product team can run, and the one most often skipped because the strategy itself feels self-evident until it is named in writing. The point of the matrix is not for Gemini to be right; it is to give the user a structured surface on which to disagree, recalibrate, and decide which assumptions to test first.

### Problem It Solves

Most product strategy collapses because the underlying assumptions were never named, let alone tested. Teams hold their bets implicitly and discover the bet was wrong only when the quarter is over. Naming assumptions explicitly is the discipline; the matrix is the artifact that makes the discipline visible.

### The Indie Hacker Angle

This demo is one tool from a larger multi-tenant SaaS suite the author is building. The production version of AdaptableProduct is a quarterly strategic planning environment for product leadership teams: it embeds all nine framework steps, supports team collaboration, longitudinal cycle comparison, decision logs with dissent preserved, and a Carryover Queue for between-cycle engagement. The production landing page is at `https://adaptableproduct.com` (placeholder).

This open source demo strips that down to one feature, runs locally, scopes everything to a single signed-in user, and is released under MIT license. Visitors can clone the repo, run `bin/setup`, sign in as the seeded admin, and have a working Assumption Matrix generator in under five minutes. The AI prompt that drives the matrix is editable in the admin UI; visitors can tune it themselves without touching code.

### Anchor Word

**Strategic.** The demo should feel like a quarterly artifact, not a backlog ticket. Generous vertical rhythm; calm typography; the matrix table is the focus, not the chrome around it.

---

## 2. Customizations Applied to the Boilerplate

| Customization | Value |
|---|---|
| `APP_NAME` | `AdaptableProduct Demo` |
| `APP_TAGLINE` | `Describe your product strategy. See the assumptions you are betting on.` |
| `APP_DESCRIPTION` | `An open source demo of the Assumption Matrix from AdaptableProduct, the quarterly companion for product leaders managing through structural change.` |
| Accent color | `#c026d3` (fuchsia) set in `app/assets/stylesheets/_accent.scss` |
| Navbar links | `Products` (index), and the user dropdown from the boilerplate |
| Home page (`home/index.html.erb`) | Replaced with the AdaptableProduct Demo landing pitch |
| Dashboard (`dashboard/show.html.erb`) | Replaced with the Products index (the primary view in this app) |
| UX pattern | **Form-then-result** with a sortable Bootstrap table for the matrix |
| AI templates seeded | `adaptableproduct_assumptions_v1` (full content in Section 7) |

Everything else (auth, layout, admin panel, Gemini service, gatekeeper, budget cap, request log, RSpec setup) is inherited unchanged from the boilerplate.

---

## 3. Data Model

Three new models, all scoped to `current_user` via `belongs_to :user` (directly or transitively).

### StrategyProduct

The user's input. One row per product strategy the user wants to surface assumptions for. A user can have many StrategyProducts; in practice most users will create one or two for the demo and iterate.

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `user_id` | uuid | `belongs_to :user` |
| `name` | string | Product name. Required. **(template variable: `{{product_name}}`)** |
| `target_customer` | string | One sentence. Required, 10 to 250 chars. **(template variable: `{{target_customer}}`)** |
| `strategy` | text | One paragraph describing the current strategy. Required, 50 to 2000 chars. **(template variable: `{{strategy}}`)** |
| `primary_goal` | text | The most important outcome this strategy is meant to produce. Required, 20 to 500 chars. **(template variable: `{{primary_goal}}`)** |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Associations**
- `belongs_to :user`
- `has_many :assumption_matrices, dependent: :destroy`
- `has_one :latest_matrix, -> { order(generated_at: :desc) }, class_name: "AssumptionMatrix"`

**Validations**
- `name`, `target_customer`, `strategy`, `primary_goal` all required
- Length bounds as above

### AssumptionMatrix

One run of the assumption surfacing prompt. A StrategyProduct can have many matrices; regenerating creates a new one rather than overwriting, so the user can compare strategy as it evolves.

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `strategy_product_id` | uuid | `belongs_to :strategy_product` |
| `generated_at` | datetime | When Gemini returned the response |
| `gemini_raw` | text | **(Gemini output, used for Show raw response toggle)** |
| `status` | string | `pending`, `completed`, `failed`. Default `pending`. |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Associations**
- `belongs_to :strategy_product`
- `has_one :user, through: :strategy_product`
- `has_many :assumptions, dependent: :destroy`

**Validations**
- `strategy_product_id` required
- `status` inclusion in the enum list above

### Assumption

One row in the matrix. Created in batch from the parsed JSON Gemini returns. The user can update `confidence_user` inline; nothing else on this row is user-editable in the demo.

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `assumption_matrix_id` | uuid | `belongs_to :assumption_matrix` |
| `statement` | text | The assumption stated as a falsifiable claim |
| `confidence_ai` | integer | 1 to 5, what Gemini estimated |
| `confidence_user` | integer | 1 to 5, the user's calibration. Nullable on creation; user can set inline. |
| `risk` | string | `low`, `medium`, `high`. What breaks if the assumption is wrong. |
| `category` | string | `customer`, `market`, `capability`, `economics`, `competitive`, `regulatory` |
| `experiment` | text | One specific suggested test, written cheap-to-expensive |
| `position` | integer | 1 to 12; preserves Gemini's original order so "ranked by leverage" is reproducible |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Associations**
- `belongs_to :assumption_matrix`
- `has_one :user, through: :assumption_matrix`

**Validations**
- `statement`, `confidence_ai`, `risk`, `category`, `experiment`, `position` required
- `confidence_ai` and `confidence_user` inclusion 1 to 5
- `risk` inclusion in `low`, `medium`, `high`
- `category` inclusion in the six values listed above

**Computed Method**
- `confidence_gap` returns `confidence_ai - confidence_user` when both are present; nil otherwise. Used for the Confidence Gap sort.

---

## 4. Routes

| Verb | Path | Controller#Action | Purpose |
|---|---|---|---|
| GET | `/products` | `strategy_products#index` | List the user's StrategyProducts. Also the dashboard view. |
| GET | `/products/new` | `strategy_products#new` | Form to create a new StrategyProduct |
| POST | `/products` | `strategy_products#create` | Create the StrategyProduct, redirect to its show page |
| GET | `/products/:id` | `strategy_products#show` | Show the product and its latest matrix (or the empty state if none) |
| GET | `/products/:id/edit` | `strategy_products#edit` | Edit the four input fields |
| PATCH | `/products/:id` | `strategy_products#update` | Update the product. Note: this does NOT regenerate the matrix; the user must explicitly run Surface Assumptions again. |
| DELETE | `/products/:id` | `strategy_products#destroy` | Delete the product and all matrices |
| POST | `/products/:id/matrices` | `assumption_matrices#create` | **Triggers the Gemini call.** Creates an AssumptionMatrix, parses the response into Assumption rows, redirects to the matrix show. |
| GET | `/products/:id/matrices/:matrix_id` | `assumption_matrices#show` | Display a specific matrix (used when comparing prior runs) |
| PATCH | `/assumptions/:id` | `assumptions#update` | Update `confidence_user` inline via Turbo Stream |

All HTML responses; the inline confidence rating returns a Turbo Stream. No JSON API. Auth and admin routes inherited from the boilerplate are not listed here.

---

## 5. Controllers and Actions

### `StrategyProductsController`

Standard RESTful seven actions, scoped to `current_user`.

- `index`: Lists `current_user.strategy_products` ordered by most recent. Also serves as the dashboard.
- `new`: Renders an empty `StrategyProduct` form.
- `create`: Persists with strong params; on success redirects to the show page; on failure re-renders `new`.
- `show`: Loads the product and its `latest_matrix`. If no matrix exists, renders the empty state with a prominent "Surface Assumptions" button. If a matrix exists, renders it as a sortable table.
- `edit`: Renders the form populated with current values.
- `update`: Updates with strong params. Note: editing the strategy fields invalidates no existing matrices; the user is shown a banner stating the latest matrix may be stale and a button to regenerate.
- `destroy`: Removes the product and cascades to its matrices and assumptions.

Strong params: `name`, `target_customer`, `strategy`, `primary_goal`.

### `AssumptionMatricesController`

Two actions: `create` (the Gemini-calling one) and `show`.

- `create`: This is the action that triggers the Gemini call. Steps:
  1. Load `current_user.strategy_products.find(params[:id])`.
  2. Build a new `AssumptionMatrix` with status `pending`.
  3. Call `GeminiService.generate(template: "adaptableproduct_assumptions_v1", variables: { product_name: ..., target_customer: ..., strategy: ..., primary_goal: ... })`.
  4. Persist the raw response to `gemini_raw`.
  5. Parse the JSON. Validate it has 8 to 12 entries each conforming to the schema (statement, confidence_ai, risk, category, experiment).
  6. Create one Assumption row per entry, preserving order via `position`.
  7. Mark the matrix `completed` and redirect to the matrix show.
  8. On parse failure: mark the matrix `failed`, store the raw response, render the show page with a friendly "the model returned malformed output, here is what it sent" panel and a retry button.
  9. On `GeminiService::GeminiError` (any subclass): the boilerplate's fail-soft partial renders inline with a retry button. The matrix record is marked `failed` with the error message captured. The boilerplate already wrote an `LlmRequest` row capturing the failure.
- `show`: Loads the matrix and its assumptions, renders the matrix table.

### `AssumptionsController`

One action: `update`. Used only to set `confidence_user` inline.

- `update`: Loads `current_user.assumptions.find(params[:id])` (scoped through the matrix and product chain). Updates `confidence_user`. Responds with a Turbo Stream that re-renders the row's "Your Confidence" cell and the "Confidence Gap" indicator.

Strong params: `confidence_user`.

All controllers inherit from `ApplicationController` (authentication required), scope through `current_user`, use strong parameters, and rescue `GeminiService::GeminiError` using the boilerplate's shared partial.

---

## 6. Views

### `home/index.html.erb` (replaced)

The public landing page. A single centered hero:
- App name in the brand font (see Section 12)
- Tagline: "Describe your product strategy. See the assumptions you are betting on."
- A 60 to 90 word paragraph framing why naming assumptions matters
- "Try it" button linking to sign up
- Below the fold, a static example of an Assumption Matrix (rendered from a fixture, no Gemini call) so visitors see what the output looks like before signing up
- Footer with a link to the production app's landing page and the GitHub repo

### `dashboard/show.html.erb` (replaced)

Renders the StrategyProducts index inline. If the user has no products, an empty state with a "Create your first product" button.

### `strategy_products/index.html.erb`

A simple Bootstrap card list of the user's StrategyProducts. Each card shows: product name, target customer (truncated), the count of assumptions in the latest matrix (or "no matrix yet"), and the date of the latest run. Card click opens the show page.

### `strategy_products/new.html.erb` and `edit.html.erb`

Single-column form, max-width 720px. Bootstrap floating labels for all four fields. Helper text under each field explains what makes a good answer:

- **Product name**: "What you call this product internally or externally"
- **Target customer**: "One specific buyer or user. Be narrow; you can broaden later."
- **Current strategy**: "How you are trying to win, in one paragraph. What is the bet?"
- **Primary goal**: "The most important outcome this strategy is meant to produce in the next quarter or two"

Submit button uses `var(--accent)`. On submit, a Stimulus `form-submit` controller disables the button and shows a spinner.

### `strategy_products/show.html.erb`

Two states.

**Empty state (no matrix exists):**
- Top: product name, the four input values rendered as a read-only summary card
- Center: a large "Surface Assumptions" button (`btn-lg`, accent color)
- Beneath the button: a short explainer of what will happen next, what the matrix will look like, and that the call typically takes 4 to 10 seconds

**Result state (a matrix exists):**
- Top: product name and edit link
- Read-only summary card for the four inputs (collapsible)
- Matrix header: "Assumption Matrix - generated [relative time]" with two action buttons: "Regenerate" (creates a new matrix) and "Show raw response" (Bootstrap collapse revealing `gemini_raw`)
- The matrix table (see below)
- A small "Stale" banner if the user has edited the strategy since this matrix was generated

### Matrix table partial: `_matrix_table.html.erb`

Sortable Bootstrap table with `table-dark` and `table-hover`. Columns:

| Column | Notes |
|---|---|
| Assumption | The `statement` text. Wraps. Widest column. |
| AI Confidence | 1 to 5, rendered as a row of 5 dots, filled to the AI's number, in `text-muted` |
| Your Confidence | 1 to 5, rendered as an interactive 5-dot rating control. Click a dot to set; submits via Turbo Stream. |
| Risk | Bootstrap badge: `bg-success` low, `bg-warning text-dark` medium, `bg-danger` high |
| Category | Plain text; six possible values |
| Experiment | The suggested test, wrapped, with a small `text-muted` label "Cheapest to test first" only on the first row when sorted by leverage |
| Confidence Gap | Computed cell. Only visible when sorted by gap. Shows `+2` or `-3` etc., color coded: positive (AI more confident than user) in fuchsia accent; negative (user more confident than AI) in muted text. |

Sort options exposed as a small button group above the table:
- Leverage (default; preserves Gemini's `position` order)
- Risk (high to low)
- Confidence Gap (largest absolute gap first; the most interesting cell where AI says high and user says low or vice versa)

Each sort option toggles a Stimulus `matrix-sort` controller that re-orders rows client-side without a server roundtrip.

### Inline rating partial: `_confidence_rating.html.erb`

Five clickable dots inside a small Turbo Frame keyed on `assumption_<id>_confidence`. Click submits a PATCH to `/assumptions/:id` and the response Turbo Stream replaces the frame with the updated state.

### Raw response toggle

Standard Bootstrap collapse. Button reads "Show raw response" / "Hide raw response". Reveals a `<pre>` block with `gemini_raw`. This is required across every demo per the boilerplate's UX expectation.

### Error partials

The boilerplate's `_gemini_error.html.erb` partial handles `GeminiError`, `GatekeeperError`, `BudgetExceededError`, and `TimeoutError` with a friendly inline alert and retry button. This demo uses it unmodified; if this app needs to add a parse-error case (Gemini returned non-JSON or wrong shape), it adds a sibling partial `_matrix_parse_error.html.erb` rendered from the matrix show in the `failed` state.

---

## 7. AI Templates and Gemini Integration

This demo seeds one AiTemplate.

### Template: `adaptableproduct_assumptions_v1`

**Description (admin UI):** "Surfaces 8 to 12 ranked, falsifiable assumptions a product strategy depends on, paired with risk, category, and a cheap-first experiment."

**System prompt:**

```
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
```

**User prompt template:**

```
Product name: {{product_name}}

Target customer: {{target_customer}}

Current strategy:
{{strategy}}

Primary goal this strategy is meant to advance:
{{primary_goal}}

Surface the 8 to 12 most consequential assumptions this strategy depends
on. Return JSON only, conforming to the schema in your instructions.
```

**Variables consumed**

| Variable | Source |
|---|---|
| `{{product_name}}` | `StrategyProduct#name` |
| `{{target_customer}}` | `StrategyProduct#target_customer` |
| `{{strategy}}` | `StrategyProduct#strategy` |
| `{{primary_goal}}` | `StrategyProduct#primary_goal` |

**Model:** `gemini-2.0-flash` (boilerplate default; sufficient for structured-JSON tasks of this size)

**`max_output_tokens`:** 2500. Slightly above the boilerplate default of 2000 because 12 assumptions with full statements and experiments push the upper end of 2000 in some runs. 2500 keeps headroom without enabling unbounded output.

**`temperature`:** 0.4. Lower than the boilerplate default of 0.7 because we want consistent, structured JSON; we are not asking the model to be creative, we are asking it to be disciplined and parseable. Higher temperatures produce more varied phrasings but also more parse failures.

**Notes (author's notes for the admin UI):**

```
This template is the entire demo. Iterate here.

Watch for:
- Assumptions that are not falsifiable (e.g., "users will love it"). Tighten the
  prompt with examples if this happens.
- Categories drifting outside the six allowed values. The schema enforcement plus
  temperature 0.4 keeps this rare.
- Generic experiments ("interview customers"). Tighten by giving examples in the
  system prompt of what specific looks like.
- Fewer than 8 or more than 12 assumptions. The validator will reject and the
  user sees a parse error. Lower temperature to 0.3 if this happens often.

Known failure modes:
- Strategies under 50 chars produce thin matrices. The form validation already
  enforces 50+ char strategy field, but watch.
- Highly novel domains (e.g., decentralized protocols) produce more "market"
  category assumptions and fewer in other categories. This is the model
  reflecting the strategy, not a bug. The user can adjust their own confidence
  to surface this.
```

**Where it's called:** `AssumptionMatricesController#create`, with the four variables drawn from the parent `StrategyProduct`.

### Response Parsing

The controller wraps the raw response in a parser that:
1. Strips any accidental markdown fence (` ```json ... ``` `) the model adds despite instructions.
2. Parses as JSON.
3. Validates the top-level `assumptions` array has 8 to 12 entries.
4. Validates each entry has all required fields with values in the allowed enums.
5. On any parse or validation failure, the matrix is marked `failed` and the raw response is stored. The user sees the parse-error partial with a retry button.

### Out of Scope For This Demo

- No streaming. The call is synchronous. The user sees a spinner.
- No function calling. This is a single-shot prompt.
- No multi-turn refinement. Regenerating creates a new matrix; the user does not chat with the model.
- No model fallback. If Gemini fails, the user retries.

The boilerplate's gatekeeper, budget cap, request log, timeout, and fail-soft UI apply automatically to every call this demo makes; they are not redescribed.

---

## 8. AI Safety Considerations (Specific to This App)

**Content sensitivity:** Low to moderate. The user is pasting their product strategy; this can include confidential or competitively sensitive material. The demo is local-only and does not transmit data anywhere except to Gemini, but the README explicitly warns: "Do not paste strategy you would not be willing to send to a third-party API."

**Consequential outputs:** A founder or product manager could in theory act on the matrix as if it were ground truth. Three mitigations:

1. The matrix UI is designed around the **user re-rating their own confidence**, which is the discipline the framework is meant to build. The "Confidence Gap" sort makes the AI's view explicit so the user can disagree visibly.
2. The boilerplate footer and a per-page banner above the matrix repeat: "These are AI-generated suggestions. The point is to challenge them, not to follow them."
3. The "Show raw response" toggle is always available so the user can see what the model actually returned, including its reasoning if it leaked any.

**Domain accuracy requirements:** Gemini may invent specific market facts, competitor moves, or customer behaviors that are not true. The matrix is framed as **assumptions to test**, not **facts to act on**, which structurally limits this risk. The experiment column reinforces the framing: every assumption ships with a way to verify it.

**App-specific disclaimers (beyond the boilerplate footer):**
- The Surface Assumptions button has helper text: "These are starting hypotheses, not facts. The point is to disagree with them."
- Above the matrix table: "AI-generated. Re-rate Your Confidence on each row. Disagreement is the data."
- The empty state explainer mentions: "The model is calibrating from your strategy text. The narrower and more specific the strategy, the sharper the assumptions."

**Tightened settings:**
- `temperature` 0.4 (vs boilerplate default 0.7) for structured JSON reliability
- `max_output_tokens` 2500 (vs default 2000) for the upper end of 12-assumption matrices
- The boilerplate's per-user daily cap of 50 calls is left at the default. A typical user will run 1 to 5 matrices for one or two products in a session; 50 is plenty of headroom and abuse-resistant.

**What this demo deliberately does NOT do (for safety reasons):**
- **No automatic regeneration.** Editing the strategy fields shows a "stale" banner but does not re-call Gemini. Every Gemini call is a deliberate user action with a visible button. This prevents a user accidentally racking up costs or surprising calls.
- **No "rewrite my strategy" feature.** The model is asked to surface assumptions, not to author or revise the strategy itself. This keeps the user's voice and judgment central.
- **No competitor-specific outputs.** The prompt does not ask Gemini to name specific competitors. Competitor-strategy stress-testing is a distinct AI template that belongs in the production app, not this demo.
- **No tone moderation on user input beyond the boilerplate's gatekeeper.** Strategy text is professional context; the gatekeeper's basic profanity check is sufficient.

**Stakes summary:** Medium. The output is read and acted on by a single person making business decisions. It is not a peer-support, legal-advice, or life-decision domain. The structural decisions (matrix framing, user re-rating, no auto-regenerate) push the user toward critical engagement rather than passive consumption.

---

## 9. RSpec Outline

### `spec/models/strategy_product_spec.rb`
- Validations on each of the four required fields, with length bounds
- Association: `belongs_to :user`, `has_many :assumption_matrices` cascading delete
- Scope: `latest_matrix` returns the most recent matrix
- Cannot be loaded for a different user (access control via scoped finder)

### `spec/models/assumption_matrix_spec.rb`
- Validations on `strategy_product_id` and `status`
- Status enum inclusion (`pending`, `completed`, `failed`)
- Association: `belongs_to :strategy_product`, `has_many :assumptions` cascading delete
- `gemini_raw` is preserved when status transitions to `failed`

### `spec/models/assumption_spec.rb`
- Validations on all required fields
- Enum validations on `risk` and `category`
- Confidence bounds (1 to 5) for both `confidence_ai` and `confidence_user`
- `confidence_user` is nullable
- `confidence_gap` returns the difference when both values are present, nil otherwise

### `spec/requests/strategy_products_spec.rb`
- A signed-in user can create, view, edit, and delete their own StrategyProducts
- A different signed-in user cannot view or edit another user's StrategyProduct (404, not 403)
- Strong params reject unknown fields
- Validation errors re-render the form with messages

### `spec/requests/assumption_matrices_spec.rb`
- POST `/products/:id/matrices` calls `GeminiService.generate` with the correct template name and variables (verified via the boilerplate's stubbed test double)
- A successful call creates one AssumptionMatrix and 8 to 12 Assumption rows
- The matrix's `gemini_raw` is set to the stubbed response
- An `LlmRequest` record is created (the boilerplate's stub still writes the log)
- A parse failure (malformed JSON from the stub) marks the matrix `failed` and renders the parse-error partial
- A `GeminiService::BudgetExceededError` from the stub renders the budget-exceeded partial without creating a matrix
- A different signed-in user cannot generate a matrix on another user's product

### `spec/requests/assumptions_spec.rb`
- PATCH `/assumptions/:id` updates `confidence_user` and returns a Turbo Stream
- A different signed-in user cannot update another user's assumption (404)
- Out-of-range `confidence_user` values are rejected

The boilerplate's specs for `User`, `AiTemplate`, `LlmRequest`, `GeminiService`, `AiGatekeeper`, `AiBudgetChecker`, sessions, registrations, passwords, and admin templates are not redescribed.

---

## 10. Seed Data

`db/seeds.rb` extends the boilerplate's seeded admin demo user (`demo@example.com` / `password123`, `admin: true`) with:

### AiTemplate seed

One record matching the full specification in Section 7:

- `name: "adaptableproduct_assumptions_v1"`
- `description: "Surfaces 8 to 12 ranked, falsifiable assumptions a product strategy depends on, paired with risk, category, and a cheap-first experiment."`
- `system_prompt`: the full text from Section 7
- `user_prompt_template`: the full text from Section 7
- `model: "gemini-2.0-flash"`
- `max_output_tokens: 2500`
- `temperature: 0.4`
- `notes`: the full author's notes from Section 7

### Domain seeds

One realistic StrategyProduct on the demo user, so a visitor cloning the repo sees something interactive immediately:

- `name`: "FieldNote"
- `target_customer`: "Solo therapists in private practice billing insurance directly"
- `strategy`: "FieldNote replaces the four-tab workflow most solo therapists use (Google Calendar, a notes doc, a billing spreadsheet, and a portal for insurance claims) with one weekly view that captures session notes and auto-generates the CPT-coded claim. We charge $39/month, beat SimplePractice on price, and win on the weekly review surface that competitors do not have."
- `primary_goal`: "Get to 200 paying solo therapists in 12 months at under $80 CAC."

A second optional seed, written but commented out, lets the visitor uncomment to see how a different domain produces a different matrix.

The seed file does NOT generate an AssumptionMatrix. The visitor runs the matrix themselves; that is the demo. The home page's "below-the-fold example matrix" is a static fixture for the unauthenticated landing view, not a seeded record.

---

## 11. README Additions

### App-specific sections (extending the boilerplate's README template)

**Title:** AdaptableProduct Demo

**Tagline:** Describe your product strategy. See the assumptions you are betting on.

**Description (one paragraph):**

AdaptableProduct Demo is an open source, single-feature taste of the production AdaptableProduct app. Enter your product name, target customer, current strategy in one paragraph, and the most important goal the strategy is meant to advance. Click Surface Assumptions, and Gemini returns 8 to 12 ranked, falsifiable assumptions your strategy depends on, each with a risk rating, a category, and a suggested experiment ordered cheapest first. Re-rate your own confidence on each row inline; the gap between the AI's confidence and yours is the most interesting cell.

**Screenshot placeholder:**

> A screenshot of the Assumption Matrix view will go here. Two-pane layout: the strategy summary on top, the sortable matrix table below, with the Confidence Gap column highlighted. Reach out if you want to contribute the screenshot.

**Why I built this:**

I built AdaptableProduct because most of the product strategy advice I have read assumes a stable strategic frame, and most of the strategies I have run did not have one. The 9-Step Adaptable Product Framework is the working version of the practice I wish I had had, and Step 3, Assumption Challenge, is the most productive single step a team can run. This demo is the smallest possible version of that step: enter the strategy, see the bets, disagree.

The full version is multi-tenant, supports team collaboration across all nine framework steps, longitudinal cycle comparison, decision logs with dissent preserved, and a Carryover Queue for between-cycle work. You can read about it at `https://adaptableproduct.com` (placeholder). This demo is MIT-licensed; the prompt that drives it is editable in the admin UI at `/admin/ai_templates`. Sign in as `demo@example.com` / `password123`, click Admin, click the template, and tune it yourself. That is the point of releasing it as data, not code.

**Editable AI prompt:**

The single AI template this demo uses is `adaptableproduct_assumptions_v1`. It lives as a row in the `ai_templates` table and is edited in the admin UI. To iterate on the prompt:

1. Sign in as the seeded admin (`demo@example.com` / `password123`)
2. Click Admin in the user dropdown
3. Click AI Templates, then the template name
4. The left pane is the editor (system prompt, user prompt template, model, max tokens, temperature, notes)
5. The right pane is the live test panel: the variables auto-detected from the prompt's `{{...}}` placeholders each get an input; click Test to call Gemini with the current draft (not saved); the response renders inline
6. When you like what you see, click Save to persist
7. Future calls to the demo will use the saved template

**Setup steps beyond `bin/setup`:**

- Sign up for a free Gemini API key at `ai.google.dev`
- Set `GEMINI_API_KEY` in `.env`
- Run `bin/setup`
- `bin/rails server`
- Sign in at `localhost:3000/sign_in` with `demo@example.com` / `password123`

**Privacy note:**

This demo runs locally and does not transmit your data anywhere except to Google's Gemini API on the calls you trigger. Treat the strategy text you paste as you would treat any other Gemini prompt: do not include information you would not be willing to send to a third party. The seed StrategyProduct (FieldNote) is fictional and safe to use as a starting point.

The boilerplate's standard sections (Stack, Setup, License, AI Safety Posture, About the Author) are unchanged.

---

## 12. Bootstrap Dark Mode and Accent Color Notes

### Pattern

Form-then-result. Two form pages (new, edit) with floating-label inputs, and one result page with a sortable Bootstrap table. No cards-as-tiles, no kanban, no wizard. Generous whitespace; the matrix table is the focus.

### Accent color

`#c026d3` is a saturated fuchsia. Set in `app/assets/stylesheets/_accent.scss`:

```scss
:root {
  --accent: #c026d3;
  --accent-hover: #a21caf;
}
```

The accent appears on:
- Primary buttons (Surface Assumptions, Save, Submit, Generate, Regenerate)
- The active dot in the Your Confidence rating control
- The Confidence Gap cell when the gap is positive (AI more confident than user)
- The brand mark in the navbar
- Active state on the navbar link
- Form field focus rings (`:focus` border and box-shadow)

The accent does NOT appear on:
- Risk badges (those use Bootstrap's semantic palette: success, warning, danger)
- Body text or links inside table cells (those stay neutral so the badges and accent stand out)
- The matrix row hover state (uses Bootstrap's default `--bs-table-hover-bg`)

### Component choices

- **Tables:** `table table-dark table-hover table-striped align-middle`. Striped rows for readability across 12 entries.
- **Buttons:** Primary actions use `.btn-primary` with `--bs-btn-bg: var(--accent)` and `--bs-btn-hover-bg: var(--accent-hover)` overrides. Secondary actions use `.btn-outline-secondary`.
- **Forms:** Bootstrap floating labels (`.form-floating`) on all four inputs. Helper text via `.form-text` under each. Validation errors via `.is-invalid` and `.invalid-feedback`.
- **Empty states:** A centered `.text-center` block with a muted icon (Bootstrap Icons `bi-lightbulb` for the empty matrix), a short heading, an explainer paragraph, and the action button. No custom illustrations; the boilerplate stays minimal.
- **Badges:** Risk uses `.badge` with semantic classes. Category uses `.badge bg-secondary`. The "Stale" banner uses `.alert .alert-warning .py-2`.
- **Collapses:** Bootstrap's native `data-bs-toggle="collapse"` for the input summary card on the matrix show page and for the Show raw response toggle. No custom JavaScript.

### Custom CSS beyond Bootstrap

Minimal, additive. Three additions only:

1. **Confidence rating control:** A small Stimulus controller (`confidence-rating`) plus 30 lines of CSS for the 5-dot rating UI. Each dot is a `<button>` with `border-radius: 50%`, default `background: var(--bs-secondary-bg)`, filled state `background: var(--accent)`. Hover state previews the rating.
2. **Confidence Gap pill:** A small inline pill (`.confidence-gap`) with `background: var(--accent); color: white; padding: 0.25rem 0.5rem; border-radius: 999px;` for positive gaps. Negative gaps render as `text-muted`.
3. **Brand mark:** The app name in the navbar uses a font-weight 700 sans-serif (system stack: `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif`). No custom font load; no Google Fonts; the demo stays fast and dependency-light.

Everything else is Bootstrap utility classes. The footer, navbar, flash container, and admin views are inherited from the boilerplate unchanged.

---

*v1.0 - AdaptableProduct Demo spec. Built on Open Demo Starter v2.0. Open source under MIT license.*
