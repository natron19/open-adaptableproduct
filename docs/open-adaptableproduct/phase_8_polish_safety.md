# Phase 8 — Polish, Safety Banners & Full Suite

**Goal:** All spec §8 safety UI in place. Accessibility basics verified. Full RSpec suite green with no real Gemini calls.

**Prerequisites:** Phases 1–7 complete. All individual phase specs passing.

**Spec reference:** `docs/open-adaptableproduct/AdaptableProduct_Demo_Spec_v1.md` §6, §8

---

## Context

This phase adds no new features. It firms up what's already built:

- Safety disclaimers that the spec requires in specific locations
- The stale-matrix banner (strategy edited after matrix generated)
- Accessibility checks (aria labels, form labels)
- A cleanup pass for any lingering hardcoded strings, debug calls, or boilerplate violations
- The full RSpec suite run as the final gate before Phase 9

---

## Safety & UX Banners

### 1. AI disclaimer banner above every matrix table

In `assumption_matrices/_matrix_table.html.erb` (or the parent view that renders it), add above the sort buttons:

```erb
<p class="text-muted small mb-3">
  <strong>AI-generated.</strong> Re-rate Your Confidence on each row. Disagreement is the data.
</p>
```

### 2. Helper text near "Surface Assumptions" button

In the empty-state section of `strategy_products/show.html.erb`, add below the button:

```erb
<p class="text-muted small mt-2">
  These are starting hypotheses, not facts. The point is to disagree with them.
</p>
```

### 3. Empty state explainer text

In the same empty-state section, ensure the explainer paragraph includes:

```
The model is calibrating from your strategy text. The narrower and more specific the
strategy, the sharper the assumptions.
```

### 4. Stale matrix banner

In `strategy_products/show.html.erb` result state, after the summary card, before the matrix:

```erb
<% if @strategy_product.updated_at > (@strategy_product.latest_matrix.generated_at || Time.at(0)) %>
  <div class="alert alert-warning py-2 d-flex align-items-center gap-3">
    <span>Your strategy has changed since this matrix was generated.</span>
    <%= button_to "Regenerate", strategy_product_assumption_matrices_path(@strategy_product),
          method: :post, class: "btn btn-outline-warning btn-sm" %>
  </div>
<% end %>
```

### 5. Boilerplate footer AI disclaimer

Confirm the layout `app/views/layouts/application.html.erb` still includes the boilerplate's AI disclaimer in the footer. Do not modify it — just verify it is present.

### 6. "Show raw response" toggle

Confirm every matrix show page has the Bootstrap collapse for `gemini_raw`. This was built in Phase 4/5 but verify it is present in both `strategy_products/show.html.erb` (latest matrix) and `assumption_matrices/show.html.erb` (specific matrix).

---

## Accessibility Checks

```
[ ] All form fields have floating labels or explicit <label> elements
[ ] All five confidence-dot buttons have aria-label="Rate N out of 5"
[ ] Sort buttons have clear text labels (they do, from Phase 4)
[ ] "Show raw response" button has descriptive text (not just an icon)
[ ] No img elements without alt attributes
```

---

## Code Cleanup

Before running the final suite, do a pass for:

```
[ ] No binding.pry or debugger calls in any file (grep -r "binding.pry\|debugger" app/)
[ ] No hardcoded "AdaptableProduct Demo" string literals in views (grep -r "AdaptableProduct Demo" app/views/)
[ ] No hardcoded hex color values outside application.css (grep -r "#c026d3\|#a21caf" app/views/ app/javascript/)
[ ] No JSON API routes added (config/routes.rb should have only HTML routes + Turbo Stream)
[ ] No Redis, Sidekiq, or external queue gems in Gemfile
[ ] All new controllers inherit from ApplicationController (not ActionController::Base)
```

---

## Full Manual Test Checklist

Run through the complete happy path plus edge cases:

```
Happy Path
[ ] Sign up as a new user → confirm redirect to dashboard/products
[ ] Create a new product with all four fields → show page with empty state
[ ] Click "Surface Assumptions" → spinner → matrix renders with 8–12 rows
[ ] "Show raw response" toggle reveals JSON from Gemini
[ ] Rate confidence on 3 or more rows → dots update without reload
[ ] Sort by "Risk" → high-risk rows first
[ ] Sort by "Confidence Gap" → gap column appears; rows sorted by largest absolute gap
[ ] Sort by "Leverage" → original Gemini order restored; gap column hidden
[ ] Click "Regenerate" → new matrix created; redirected to new matrix show

Edit & Stale Banner
[ ] Edit the product strategy after a matrix exists → save → return to show page
[ ] Stale banner appears above the matrix with a "Regenerate" button
[ ] Click Regenerate from the banner → new matrix generated, banner disappears

Error States
[ ] Admin: temporarily break the template JSON → Surface Assumptions → parse error partial with retry
[ ] Admin: temporarily set invalid GEMINI_API_KEY → Surface Assumptions → ai_error partial
[ ] Restore template and key after each test

Access Control
[ ] Sign up as a second user → attempt GET /products/:first_user_product_id → 404
[ ] Attempt DELETE /products/:first_user_product_id → 404

Admin Panel
[ ] /admin/llm_requests shows all calls with correct statuses
[ ] /admin/ai_templates → edit adaptableproduct_assumptions_v1 → Test panel fires and returns JSON

Infrastructure
[ ] GET /up/llm returns {"status":"ok",...}
[ ] GET /up returns 200
[ ] No JavaScript console errors on any page
[ ] Dark mode renders correctly; no white-on-white unreadable text
[ ] Accent color #c026d3 appears on: primary buttons, active confidence dot, positive gap pill, navbar brand
[ ] Unauthenticated GET /products → redirect to /sign_in
[ ] Home page loads without authentication; hero and static example matrix visible
[ ] Delete a product → product, all matrices, all assumptions gone (cascade confirmed in /admin or console)
```

---

## RSpec — Full Suite

Run the full suite with documentation format so failures are easy to trace:

```bash
bundle exec rspec --format documentation
```

All of the following must be green:

```
spec/models/strategy_product_spec.rb
spec/models/assumption_matrix_spec.rb
spec/models/assumption_spec.rb
spec/requests/strategy_products_spec.rb
spec/requests/assumption_matrices_spec.rb
spec/requests/assumptions_spec.rb
```

Plus all boilerplate specs:

```
spec/models/user_spec.rb
spec/models/ai_template_spec.rb
spec/models/llm_request_spec.rb
spec/services/gemini_service_spec.rb
spec/services/ai_gatekeeper_spec.rb
spec/services/ai_budget_checker_spec.rb
spec/requests/sessions_spec.rb
spec/requests/registrations_spec.rb
spec/requests/passwords_spec.rb
spec/requests/admin/dashboard_spec.rb
spec/requests/admin/users_spec.rb
spec/requests/admin/llm_requests_spec.rb
spec/requests/admin/ai_templates_spec.rb
```

**Zero real Gemini API calls during the test run.** Confirm by checking `spec/support/gemini_test_double.rb` is configured to stub all calls globally, or verify no HTTP requests are made during the run.

All specs green → proceed to Phase 9.
