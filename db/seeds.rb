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
  t.description       = "Surfaces 8 to 12 ranked, falsifiable assumptions a product strategy depends on, paired with risk, category, and a cheap-first experiment."
  t.model             = "gemini-2.5-flash"
  t.max_output_tokens = 8192
  t.temperature       = 0.4
  t.system_prompt     = <<~PROMPT.strip
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

# ── Client products for demo@example.com ──────────────────────────────────────
demo = User.find_by!(email: "demo@example.com")

clients = [
  {
    name:            "FieldNote",
    target_customer: "Solo therapists in private practice billing insurance directly",
    strategy:        "FieldNote replaces the four-tab workflow most solo therapists use (Google Calendar, a notes doc, a billing spreadsheet, and a portal for insurance claims) with one weekly view that captures session notes and auto-generates the CPT-coded claim. We charge $39/month, beat SimplePractice on price, and win on the weekly review surface that competitors do not have.",
    primary_goal:    "Get to 200 paying solo therapists in 12 months at under $80 CAC."
  },
  {
    name:            "ClearRoute",
    target_customer: "Operations managers at regional freight brokerages (20–200 employees)",
    strategy:        "ClearRoute gives freight brokers a real-time lane intelligence dashboard that surfaces which lanes are margin-positive today based on current spot rates and their historical cost data. We sell at $299/month as an add-on to whatever TMS they already run. We win against spreadsheets and gut instinct, not against enterprise TMS providers.",
    primary_goal:    "Sign 50 paying brokerages in 6 months at under $400 CAC through direct outbound."
  },
  {
    name:            "PinPoint",
    target_customer: "Project managers at residential general contractors running 5–25 active jobsites",
    strategy:        "PinPoint replaces the daily phone-tag loop between GCs and subcontractors with a jobsite feed: subs post a photo + status update each morning, the GC sees every site in one view, and schedule slippage is flagged automatically before it compounds. We charge $199/month per GC account with unlimited sub logins. We win by eliminating the coordination overhead that causes most residential projects to run 3–4 weeks late.",
    primary_goal:    "Reach $50K MRR within 18 months by closing 250 GC accounts through referral and trade-show outbound."
  },
  {
    name:            "Credenza",
    target_customer: "Managing partners at boutique law firms (3–15 attorneys) handling transactional work",
    strategy:        "Credenza automates the matter-opening checklist — conflict check, engagement letter generation, trust account setup, and client portal provisioning — collapsing a 90-minute admin process to under 5 minutes. We price at $149/attorney/month and position against the compliance risk of skipping steps, not against practice management software incumbents like Clio.",
    primary_goal:    "Close 100 law firm accounts in 12 months, targeting firms that have had at least one bar complaint related to intake process failures."
  },
  {
    name:            "PulseBoard",
    target_customer: "Multi-unit restaurant operators managing 3–12 quick-service locations",
    strategy:        "PulseBoard consolidates the four dashboards a multi-unit operator checks each morning — POS sales, labor scheduling, food cost variance, and Google review score — into a single exception-based digest delivered by 7 AM. We charge $99/location/month and win by cutting the operator's morning review from 45 minutes to 8 minutes. We do not compete with Toast or Square; we sit on top of them.",
    primary_goal:    "Reach 500 paying locations within 24 months by partnering with regional restaurant associations and franchise development consultants."
  },
  {
    name:            "GrantPath",
    target_customer: "Development directors at community nonprofits with $500K–$5M annual budgets",
    strategy:        "GrantPath turns a nonprofit's program descriptions and outcome data into a reusable content library, then uses that library to draft grant applications matched to open RFPs. The development director reviews and submits; GrantPath handles research and first-draft writing. We charge $299/month and position against the $3,000–$8,000 per-grant cost of outsourcing to freelance grant writers.",
    primary_goal:    "Reach 300 paying nonprofits in 18 months by converting inbound leads from foundation program officers who refer their grantees."
  },
  {
    name:            "ShiftSync",
    target_customer: "Owners of independent home care agencies (10–80 caregivers) in states with EVV mandates",
    strategy:        "ShiftSync combines electronic visit verification (required by law), caregiver scheduling, and Medicaid billing into a single mobile-first workflow. Caregivers clock in via GPS-tagged photo; the visit record flows automatically to the billing queue. We charge $12/active caregiver/month and win against legacy EVV platforms that require desktop access and charge per-claim billing fees on top of the subscription.",
    primary_goal:    "Reach 150 agency accounts covering 5,000 active caregivers within 18 months, targeting states where EVV compliance deadlines fall in the next 12 months."
  },
  {
    name:            "Versa",
    target_customer: "HR managers at professional services firms (50–300 employees) with high contractor mix",
    strategy:        "Versa automates the compliance paperwork layer for contract workforce: onboarding packets, I-9 verification, classification questionnaires, and contractor invoice reconciliation. It plugs into the HR system of record via API and handles the contractor lifecycle that Workday and BambooHR deliberately leave out. We sell at $8/contractor/month with a $500/month floor.",
    primary_goal:    "Sign 80 accounts in 12 months by targeting firms that have received IRS notices about worker misclassification in the past 24 months."
  }
]

clients.each do |attrs|
  StrategyProduct.find_or_create_by!(user: demo, name: attrs[:name]) do |sp|
    sp.target_customer = attrs[:target_customer]
    sp.strategy        = attrs[:strategy]
    sp.primary_goal    = attrs[:primary_goal]
  end
  puts "Seeded: #{attrs[:name]}"
end
