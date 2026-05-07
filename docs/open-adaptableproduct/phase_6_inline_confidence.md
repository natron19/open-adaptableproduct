# Phase 6 — Inline Confidence Rating (Turbo Stream)

**Goal:** Clicking a confidence dot on any assumption row updates `confidence_user` and re-renders that cell and the Confidence Gap cell via Turbo Stream — no page reload.

**Prerequisites:** Phase 5 complete. Gemini call works end-to-end and matrix renders.

**Spec reference:** `docs/open-adaptableproduct/AdaptableProduct_Demo_Spec_v1.md` §5 (AssumptionsController), §6 (_confidence_rating.html.erb)

---

## Context

### Turbo Stream rule

Always use `turbo_stream.update`. Never use `turbo_stream.replace`. The `replace` action destroys DOM elements and breaks Stimulus bindings after the first use. `update` replaces only the inner content, preserving the element and its bindings.

### Scope chain

`AssumptionsController#update` must scope through `current_user` all the way down to the `Assumption`. Never load an assumption directly by ID without verifying ownership. The correct pattern uses a scoped join:

```ruby
@assumption = Assumption
  .joins(assumption_matrix: :strategy_product)
  .where(strategy_products: { user_id: current_user.id })
  .find(params[:id])
```

If the assumption belongs to a different user, `find` raises `ActiveRecord::RecordNotFound`, which Rails renders as a 404 automatically (assuming `rescue_from` is set in the boilerplate, or it will produce a 500 in development — confirm the boilerplate handles this).

---

## Task 1: Complete `AssumptionsController#update`

Replace the Phase 3 stub with the full Turbo Stream response:

```ruby
class AssumptionsController < ApplicationController
  def update
    @assumption = Assumption
      .joins(assumption_matrix: :strategy_product)
      .where(strategy_products: { user_id: current_user.id })
      .find(params[:id])

    if @assumption.update(assumption_params)
      render turbo_stream: [
        turbo_stream.update(
          "assumption_#{@assumption.id}_confidence",
          partial: "assumptions/confidence_rating",
          locals: { assumption: @assumption }
        ),
        turbo_stream.update(
          "assumption_#{@assumption.id}_gap",
          partial: "assumptions/confidence_gap",
          locals: { assumption: @assumption }
        )
      ]
    else
      head :unprocessable_entity
    end
  end

  private

  def assumption_params
    params.require(:assumption).permit(:confidence_user)
  end
end
```

## Task 2: Add Confidence Gap Turbo Frame to the Matrix Table

Each row in `_matrix_table.html.erb` needs a named Turbo Frame for the gap cell so the Turbo Stream update has a target:

```erb
<td class="d-none gap-col">
  <%= turbo_frame_tag "assumption_#{assumption.id}_gap" do %>
    <%= render "assumptions/confidence_gap", assumption: assumption %>
  <% end %>
</td>
```

### `app/views/assumptions/_confidence_gap.html.erb`

```erb
<% gap = assumption.confidence_gap %>
<% if gap %>
  <span class="<%= gap > 0 ? 'confidence-gap-positive' : 'text-muted' %>">
    <%= gap > 0 ? "+#{gap}" : gap.to_s %>
  </span>
<% else %>
  <span class="text-muted">—</span>
<% end %>
```

## Task 3: Update `_confidence_rating.html.erb` Turbo Frame

The Turbo Frame tag must match the ID used in the Turbo Stream response (`assumption_<id>_confidence`). Verify the partial already uses this ID from Phase 4. The frame content is the dot rating control — clicking a dot submits a PATCH via the `confidence-rating` Stimulus controller and the Turbo Stream response updates the frame content.

The frame does NOT need `src:` — it is updated by the Turbo Stream response, not by a frame navigation.

---

## Manual Checks

```
[ ] Navigate to a completed matrix (Phase 5 must be working first)
[ ] Click a dot on any assumption row — the Your Confidence cell updates without page reload
[ ] Click a different dot on the same row — updates again correctly
[ ] Click dots on two different rows — both update independently
[ ] After rating, switch sort to "Confidence Gap" — rows re-sort client-side; gap values visible in the column
[ ] Positive gap (AI more confident than user) shows fuchsia accent pill
[ ] Negative gap (user more confident than AI) shows muted text
[ ] Open a second browser tab signed in as a different user — attempt PATCH /assumptions/:id for the first user's assumption — confirm 404 response (use DevTools Network tab or curl)
[ ] No JavaScript console errors during any rating interaction
```

---

## RSpec

Write `spec/requests/assumptions_spec.rb`. Required coverage:

- `PATCH /assumptions/:id` with valid `confidence_user` (1–5) updates the record and returns a Turbo Stream response
- Response `Content-Type` is `text/vnd.turbo-stream.html`
- The Turbo Stream response contains `turbo-stream` elements targeting `assumption_<id>_confidence` and `assumption_<id>_gap`
- `PATCH /assumptions/:id` with `confidence_user: 0` (out of range) returns 422
- `PATCH /assumptions/:id` with `confidence_user: 6` (out of range) returns 422
- A different signed-in user cannot update another user's assumption (404)
- Unauthenticated request redirects to sign in

```bash
bundle exec rspec spec/requests/assumptions_spec.rb
```

Then run the full suite:

```bash
bundle exec rspec
```
