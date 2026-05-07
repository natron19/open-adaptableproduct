FactoryBot.define do
  factory :strategy_product do
    association :user
    name            { "FieldNote" }
    target_customer { "Solo therapists in private practice billing insurance directly" }
    strategy        { "FieldNote replaces the four-tab workflow most solo therapists use (Google Calendar, a notes doc, a billing spreadsheet, and a portal for insurance claims) with one weekly view that captures session notes and auto-generates the CPT-coded claim. We charge $39/month, beat SimplePractice on price, and win on the weekly review surface that competitors do not have." }
    primary_goal    { "Get to 200 paying solo therapists in 12 months at under $80 CAC." }
  end
end
