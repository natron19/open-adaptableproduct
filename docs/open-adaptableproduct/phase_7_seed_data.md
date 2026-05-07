# Phase 7 — Seed Data

**Goal:** `rails db:seed` (and `rails db:reset && rails db:seed`) produces a realistic starting state so a cloner sees something interactive immediately after setup.

**Prerequisites:** Phase 5 complete (the `adaptableproduct_assumptions_v1` AiTemplate seed is added in Phase 5). Models, migrations, and the full CRUD flow all working.

**Spec reference:** `docs/open-adaptableproduct/AdaptableProduct_Demo_Spec_v1.md` §10

---

## Context

The boilerplate's seed creates `demo@example.com` / `password123` with `admin: true`. This phase extends that seed with:

1. A realistic `StrategyProduct` on the demo user so visitors see something on the products index immediately
2. A second, commented-out seed block for a different domain (so the visitor can uncomment to see variety)

Do NOT seed an `AssumptionMatrix`. The visitor runs the matrix themselves — that is the demo.

All seeds must be idempotent: `rails db:seed` twice must not duplicate records.

---

## `db/seeds.rb` additions

Add after the boilerplate's user seed (the admin demo user must already exist at this point):

```ruby
# -- AdaptableProduct Demo: StrategyProduct seed --

demo_user = User.find_by!(email: "demo@example.com")

StrategyProduct.find_or_create_by!(user: demo_user, name: "FieldNote") do |sp|
  sp.target_customer = "Solo therapists in private practice billing insurance directly"
  sp.strategy = "FieldNote replaces the four-tab workflow most solo therapists use (Google Calendar, a notes doc, a billing spreadsheet, and a portal for insurance claims) with one weekly view that captures session notes and auto-generates the CPT-coded claim. We charge $39/month, beat SimplePractice on price, and win on the weekly review surface that competitors do not have."
  sp.primary_goal = "Get to 200 paying solo therapists in 12 months at under $80 CAC."
end

# -- Optional second seed (uncomment to see a different domain matrix) --
# StrategyProduct.find_or_create_by!(user: demo_user, name: "ClearRoute") do |sp|
#   sp.target_customer = "Operations managers at regional freight brokerages (20–200 employees)"
#   sp.strategy = "ClearRoute gives freight brokers a real-time lane intelligence dashboard that surfaces which lanes are margin-positive today based on current spot rates and their historical cost data. We sell at $299/month as an add-on to whatever TMS they already run. We win against spreadsheets and gut instinct, not against enterprise TMS providers."
#   sp.primary_goal = "Sign 50 paying brokerages in 6 months at under $400 CAC through direct outbound."
# end
```

The `find_or_create_by!` on `name:` within the user's scope is sufficient for idempotency since names are unique per user in practice (no uniqueness constraint in the DB, but the seed only creates one record per name).

---

## Manual Checks

```
[ ] rails db:seed runs without errors (first run)
[ ] rails db:seed runs again without duplicating records (idempotency check)
[ ] Sign in as demo@example.com / password123
[ ] /products index shows the FieldNote product card
[ ] Click FieldNote — show page displays with empty state and "Surface Assumptions" button
[ ] Run Surface Assumptions on FieldNote — matrix generates successfully (requires GEMINI_API_KEY)
[ ] Uncomment the ClearRoute seed, run rails db:seed, sign in — second product appears on /products
[ ] Re-comment ClearRoute and run rails db:reset && rails db:seed — back to one product only
```

---

## RSpec

No new specs in this phase. Run the full suite to confirm the seed data and updated `seeds.rb` don't break anything:

```bash
bundle exec rspec
```

All specs must remain green. Note: RSpec uses the test database with factories — the seed file is not used in the test suite. But confirm `db/seeds.rb` can be loaded with `rails db:seed:replant` (or `db:reset db:seed`) without error.
