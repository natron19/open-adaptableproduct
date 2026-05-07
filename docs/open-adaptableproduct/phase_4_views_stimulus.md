# Phase 4 — Views & Stimulus Controllers

**Goal:** All views implemented. Full CRUD for StrategyProducts works in the browser. The "Surface Assumptions" button exists but does not yet call Gemini (that's Phase 5).

**Prerequisites:** Phase 3 complete. All routes and controller skeletons in place.

**Spec reference:** `docs/open-adaptableproduct/AdaptableProduct_Demo_Spec_v1.md` §6, §12

---

## Context

### Rules to follow in every view

- No inline JavaScript. No `onclick` or `<script>` tags. Use `data-action`, `data-controller`, `data-target`.
- All app name references: `ENV.fetch("APP_NAME", "AdaptableProduct Demo")` — never hardcode.
- Bootstrap dark mode is already on `<html data-bs-theme="dark">` in the layout.
- Use `turbo_stream.update` in any Turbo Stream response. Never `turbo_stream.replace`.
- Accent color is `var(--accent)` — use it for primary buttons and the brand mark only.

### Layout and page structure

Standard page structure (inherited from boilerplate layout):

```erb
<div class="container py-4">
  <div class="row">
    <div class="col">
      <!-- content -->
    </div>
  </div>
</div>
```

No modals. No complex overlays. Standard Rails CRUD pages with `_form` partials.

---

## Views

### Home page (replaced): `app/views/home/index.html.erb`

Public landing page. Structure:

1. Centered hero: app name (bold, system font stack), tagline from `ENV.fetch("APP_TAGLINE", "")`, 60–90 word paragraph explaining why naming assumptions matters.
2. "Try it" button → `sign_up_path`
3. Below the fold: a **static** example Assumption Matrix rendered as plain HTML (hardcoded rows, no DB query). This shows visitors what the output looks like before signing up.
4. Footer: link to production app (`https://adaptableproduct.com`) and GitHub repo URL.

No Gemini calls on this page.

### Dashboard (replaced): `app/views/dashboard/show.html.erb`

```erb
<% content_for :title, "My Products" %>
<%= render "strategy_products/product_list", strategy_products: current_user.strategy_products.order(created_at: :desc) %>
```

Or render the index partial inline. If the user has no products, show an empty state with a "Create your first product" button → `new_strategy_product_path`.

### `app/views/strategy_products/index.html.erb`

Bootstrap card list. Each card shows:
- Product name (heading, links to `strategy_product_path`)
- `target_customer` truncated to 80 chars
- Count of assumptions in `latest_matrix` or "no matrix yet"
- Date of latest run (relative time via `time_ago_in_words`)

If no products, render the empty state with "Create your first product" button.

### `app/views/strategy_products/_form.html.erb`

Single-column form, `max-width: 720px`. Bootstrap floating labels (`.form-floating`) on all four fields. Helper text (`.form-text`) under each:

- **Product name**: "What you call this product internally or externally"
- **Target customer**: "One specific buyer or user. Be narrow; you can broaden later."
- **Current strategy**: "How you are trying to win, in one paragraph. What is the bet?"
- **Primary goal**: "The most important outcome this strategy is meant to produce in the next quarter or two"

Submit button: `data-controller="form-submit" data-action="submit->form-submit#disable"`. This is the Stimulus controller that disables the button and shows a spinner.

Render validation errors with `.is-invalid` and `.invalid-feedback` on each field.

### `app/views/strategy_products/new.html.erb`

```erb
<% content_for :title, "New Product" %>
<h1 class="mb-4">Add a Product</h1>
<%= render "form", strategy_product: @strategy_product %>
```

### `app/views/strategy_products/edit.html.erb`

Same structure, title "Edit Product".

### `app/views/strategy_products/show.html.erb`

**Two states based on `@strategy_product.latest_matrix`:**

**Empty state (no matrix):**
```
Product name + edit link
Four-field read-only summary card
Large "Surface Assumptions" button (btn-lg, accent color)
  → POST to strategy_product_assumption_matrices_path(@strategy_product)
Explainer paragraph: what will happen, what the matrix looks like, call takes 4–10 seconds
Helper text near button: "These are starting hypotheses, not facts. The point is to disagree with them."
```

**Result state (matrix exists):**
```
Product name + edit link
Read-only summary card (Bootstrap collapse, starts expanded)
Matrix header: "Assumption Matrix — generated [relative time]"
  Buttons: "Regenerate" (POST to create a new matrix) | "Show raw response" (Bootstrap collapse)
AI disclaimer banner: "AI-generated. Re-rate Your Confidence on each row. Disagreement is the data."
<%= render "assumption_matrices/matrix_table", assumptions: @strategy_product.latest_matrix.assumptions.order(:position) %>
Stale banner: if strategy_product.updated_at > latest_matrix.generated_at, show .alert.alert-warning
  "Your strategy has changed since this matrix was generated." + "Regenerate" button
Raw response collapse: <pre><%= @strategy_product.latest_matrix.gemini_raw %></pre>
```

### `app/views/assumption_matrices/show.html.erb`

Renders a specific (possibly older) matrix. Same result-state layout as above, with the specific `@matrix` instead of `latest_matrix`.

### `app/views/assumption_matrices/_matrix_table.html.erb`

Sortable Bootstrap table partial. Takes `assumptions:` local.

```html
<div data-controller="matrix-sort">
  <div class="btn-group mb-3">
    <button data-action="click->matrix-sort#sortByLeverage"   class="btn btn-outline-secondary btn-sm active">Leverage</button>
    <button data-action="click->matrix-sort#sortByRisk"       class="btn btn-outline-secondary btn-sm">Risk</button>
    <button data-action="click->matrix-sort#sortByGap"        class="btn btn-outline-secondary btn-sm">Confidence Gap</button>
  </div>

  <table class="table table-dark table-hover table-striped align-middle" data-matrix-sort-target="table">
    <thead>
      <tr>
        <th>Assumption</th>
        <th>AI Confidence</th>
        <th>Your Confidence</th>
        <th>Risk</th>
        <th>Category</th>
        <th>Experiment</th>
        <th class="d-none gap-col">Confidence Gap</th>
      </tr>
    </thead>
    <tbody>
      <% assumptions.each do |assumption| %>
        <tr data-position="<%= assumption.position %>"
            data-risk="<%= assumption.risk %>"
            data-gap="<%= assumption.confidence_gap&.abs || 0 %>">
          <td><%= assumption.statement %></td>
          <td><!-- 5 filled/empty dots using var(--accent) --></td>
          <td>
            <%= render "assumptions/confidence_rating", assumption: assumption %>
          </td>
          <td>
            <% badge = { "low" => "success", "medium" => "warning text-dark", "high" => "danger" } %>
            <span class="badge bg-<%= badge[assumption.risk] %>"><%= assumption.risk %></span>
          </td>
          <td><span class="badge bg-secondary"><%= assumption.category %></span></td>
          <td class="text-muted small"><%= assumption.experiment %></td>
          <td class="d-none gap-col">
            <% if assumption.confidence_gap %>
              <% gap = assumption.confidence_gap %>
              <span class="<%= gap > 0 ? 'confidence-gap-positive' : 'text-muted' %>">
                <%= gap > 0 ? "+#{gap}" : gap.to_s %>
              </span>
            <% end %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

### `app/views/assumption_matrices/_matrix_parse_error.html.erb`

Renders when `@matrix.status == "failed"` due to a JSON parse error:

```erb
<div class="alert alert-warning">
  <strong>The AI returned a response that could not be parsed.</strong>
  <p>This can happen when the model deviates from the JSON schema. Click Retry to try again, or edit the template in the admin panel.</p>
  <%= button_to "Retry", strategy_product_assumption_matrices_path(@strategy_product),
        method: :post, class: "btn btn-outline-warning btn-sm mt-2" %>
</div>

<details class="mt-3">
  <summary class="text-muted small">Show raw response</summary>
  <pre class="mt-2 small"><%= @matrix.gemini_raw %></pre>
</details>
```

### `app/views/assumptions/_confidence_rating.html.erb`

Inside a Turbo Frame keyed on `assumption_<id>_confidence`:

```erb
<%= turbo_frame_tag "assumption_#{assumption.id}_confidence" do %>
  <div data-controller="confidence-rating"
       data-confidence-rating-value-value="<%= assumption.confidence_user || 0 %>"
       data-confidence-rating-url-value="<%= assumption_path(assumption) %>">
    <% 5.times do |i| %>
      <button type="button"
              class="confidence-dot"
              data-action="click->confidence-rating#rate"
              data-value="<%= i + 1 %>"
              aria-label="Rate <%= i + 1 %> out of 5">
      </button>
    <% end %>
  </div>
<% end %>
```

---

## Stimulus Controllers

### `app/javascript/controllers/form_submit_controller.js`

Disables the submit button and shows a spinner when the form submits. Re-enables on a Turbo error event (so users can retry if the server returns a validation error).

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  disable(event) {
    const btn = this.element.querySelector("[type=submit]")
    if (!btn) return
    btn.disabled = true
    btn.dataset.originalText = btn.textContent
    btn.textContent = "Saving…"
  }
}
```

Listen for `turbo:submit-end` on the form to re-enable on error:

```js
connect() {
  this.element.addEventListener("turbo:submit-end", (e) => {
    if (!e.detail.success) this.enable()
  })
}

enable() {
  const btn = this.element.querySelector("[type=submit]")
  if (!btn) return
  btn.disabled = false
  btn.textContent = btn.dataset.originalText || "Submit"
}
```

### `app/javascript/controllers/matrix_sort_controller.js`

Re-orders table body rows client-side. No server call.

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["table"]

  sortByLeverage() {
    this.sort((a, b) => parseInt(a.dataset.position) - parseInt(b.dataset.position))
    this.toggleGapColumn(false)
  }

  sortByRisk() {
    const order = { high: 0, medium: 1, low: 2 }
    this.sort((a, b) => order[a.dataset.risk] - order[b.dataset.risk])
    this.toggleGapColumn(false)
  }

  sortByGap() {
    this.sort((a, b) => parseFloat(b.dataset.gap) - parseFloat(a.dataset.gap))
    this.toggleGapColumn(true)
  }

  sort(compareFn) {
    const tbody = this.tableTarget.querySelector("tbody")
    const rows = Array.from(tbody.querySelectorAll("tr"))
    rows.sort(compareFn).forEach(row => tbody.appendChild(row))
  }

  toggleGapColumn(visible) {
    this.element.querySelectorAll(".gap-col").forEach(el => {
      el.classList.toggle("d-none", !visible)
    })
  }
}
```

### `app/javascript/controllers/confidence_rating_controller.js`

Handles dot rating UI and submits via Turbo Frame.

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { value: Number, url: String }

  rate(event) {
    const rating = parseInt(event.currentTarget.dataset.value)
    this.valueValue = rating
    this.render()
    this.submit(rating)
  }

  render() {
    this.element.querySelectorAll(".confidence-dot").forEach((dot, i) => {
      dot.classList.toggle("filled", i < this.valueValue)
    })
  }

  async submit(rating) {
    const form = new FormData()
    form.append("assumption[confidence_user]", rating)
    form.append("_method", "patch")
    await fetch(this.urlValue, {
      method: "POST",
      headers: { "X-CSRF-Token": document.querySelector("[name='csrf-token']")?.content },
      body: form
    })
  }
}
```

---

## CSS

Add to `app/assets/stylesheets/application.css`:

```css
/* Confidence rating dots */
.confidence-dot {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  border: none;
  background: var(--bs-secondary-bg);
  margin: 0 2px;
  cursor: pointer;
  transition: background 0.1s;
}
.confidence-dot.filled,
.confidence-dot:hover {
  background: var(--accent);
}

/* Confidence Gap positive pill */
.confidence-gap-positive {
  background: var(--accent);
  color: white;
  padding: 0.2rem 0.5rem;
  border-radius: 999px;
  font-size: 0.85em;
}

/* Accent button overrides */
.btn-accent {
  --bs-btn-bg: var(--accent);
  --bs-btn-hover-bg: var(--accent-hover);
  --bs-btn-border-color: var(--accent);
  --bs-btn-hover-border-color: var(--accent-hover);
  color: white;
}
```

---

## Manual Checks

```
[ ] Sign in, navigate to /products — empty state with "Create your first product" button
[ ] Create a new product — form saves, redirects to show page
[ ] Show page with no matrix: empty state with "Surface Assumptions" button and explainer
[ ] Edit a product — changes save, redirect to show
[ ] Delete a product — gone from index
[ ] Form submit button disables and shows "Saving…" on submit (test with DevTools throttle)
[ ] Home page: hero renders with tagline; static example matrix visible below fold
[ ] Dashboard at /dashboard renders the products list (or empty state)
[ ] Matrix sort buttons visible on show page when a matrix fixture is present (can test via console: create records manually)
[ ] No JavaScript console errors on any page
[ ] No hardcoded "AdaptableProduct Demo" strings in view source — all from ENV
```

---

## RSpec

Write `spec/requests/strategy_products_spec.rb`. Required coverage:

- Unauthenticated `GET /products` redirects to sign in
- Signed-in user can `GET /products` (200)
- Signed-in user can create a product via `POST /products` with valid params (redirects)
- Signed-in user gets form re-rendered with invalid params (422)
- Signed-in user can view their own product via `GET /products/:id` (200)
- Different signed-in user gets 404 on `GET /products/:id` for another user's product
- Signed-in user can update their own product via `PATCH /products/:id`
- Different signed-in user gets 404 on `PATCH /products/:id` for another user's product
- Signed-in user can delete their own product via `DELETE /products/:id`
- Strong params: unknown fields are ignored (or verify the permitted list)

```bash
bundle exec rspec spec/requests/strategy_products_spec.rb
```
