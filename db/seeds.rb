# Admin user — credentials for local demo use only
User.find_or_create_by!(email: "demo@example.com") do |u|
  u.name                  = "Demo User"
  u.password              = "password123"
  u.password_confirmation = "password123"
  u.admin                 = true
end

puts "Demo user: demo@example.com / password123"

# Health ping template — used by /up/llm
AiTemplate.find_or_create_by!(name: "health_ping") do |t|
  t.description          = "Minimal prompt used by the /up/llm health check endpoint."
  t.system_prompt        = "You are a health check endpoint. Respond with exactly: ok"
  t.user_prompt_template = "ping"
  t.model                = "gemini-2.5-flash"
  t.max_output_tokens    = 10
  t.temperature          = 0.0
  t.notes                = "Do not modify. Used by HealthController#llm."
end

puts "Seeded: health_ping AI template"

# AdaptableProduct assumptions template
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

puts "Seeded: adaptableproduct_assumptions_v1 AI template"

# ── Domain seed ────────────────────────────────────────────────────────────────
demo_user = User.find_by!(email: "demo@example.com")

StrategyProduct.find_or_create_by!(user: demo_user, name: "FieldNote") do |sp|
  sp.target_customer = "Solo therapists in private practice billing insurance directly"
  sp.strategy        = "FieldNote replaces the four-tab workflow most solo therapists use (Google Calendar, a notes doc, a billing spreadsheet, and a portal for insurance claims) with one weekly view that captures session notes and auto-generates the CPT-coded claim. We charge $39/month, beat SimplePractice on price, and win on the weekly review surface that competitors do not have."
  sp.primary_goal    = "Get to 200 paying solo therapists in 12 months at under $80 CAC."
end

puts "Seeded: FieldNote strategy product"

# ── Optional second seed ───────────────────────────────────────────────────────
# Uncomment to see how a different domain produces a different matrix.
# Re-comment and run rails db:seed again to remove it.
#
# StrategyProduct.find_or_create_by!(user: demo_user, name: "ClearRoute") do |sp|
#   sp.target_customer = "Operations managers at regional freight brokerages (20-200 employees)"
#   sp.strategy        = "ClearRoute gives freight brokers a real-time lane intelligence dashboard that surfaces which lanes are margin-positive today based on current spot rates and their historical cost data. We sell at $299/month as an add-on to whatever TMS they already run. We win against spreadsheets and gut instinct, not against enterprise TMS providers."
#   sp.primary_goal    = "Sign 50 paying brokerages in 6 months at under $400 CAC through direct outbound."
# end
