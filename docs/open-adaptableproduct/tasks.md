# AdaptableProduct Demo — Build Tracker

**Spec:** `docs/open-adaptableproduct/AdaptableProduct_Demo_Spec_v1.md`  
**Boilerplate:** Open Demo Starter (open-base) — already installed in this repo  
**Stack:** Rails 8.1, PostgreSQL (UUID PKs), Bootstrap 5 dark, Stimulus + Turbo, Gemini AI

Load the phase doc into context alongside this tracker. Each phase is self-contained.

---

## Phases

| # | Phase | Doc | Status |
|---|---|---|---|
| 1 | Config & Branding | [phase_1_config_branding.md](phase_1_config_branding.md) | `[x]` |
| 2 | Data Models & Database | [phase_2_data_models.md](phase_2_data_models.md) | `[x]` |
| 3 | Routes & Controller Skeletons | [phase_3_routes_controllers.md](phase_3_routes_controllers.md) | `[x]` |
| 4 | Views & Stimulus Controllers | [phase_4_views_stimulus.md](phase_4_views_stimulus.md) | `[x]` |
| 5 | AI Integration | [phase_5_ai_integration.md](phase_5_ai_integration.md) | `[x]` |
| 6 | Inline Confidence Rating | [phase_6_inline_confidence.md](phase_6_inline_confidence.md) | `[x]` |
| 7 | Seed Data | [phase_7_seed_data.md](phase_7_seed_data.md) | `[x]` |
| 8 | Polish, Safety & Full Suite | [phase_8_polish_safety.md](phase_8_polish_safety.md) | `[x]` |
| 9 | Pre-Publish Security Check | [phase_9_pre_publish.md](phase_9_pre_publish.md) | `[x]` |

---

## Quick Reference

### Route Helpers

```
strategy_products_path                          # GET  /products
new_strategy_product_path                       # GET  /products/new
strategy_product_path(id)                       # GET  /products/:id
edit_strategy_product_path(id)                  # GET  /products/:id/edit
strategy_product_assumption_matrices_path(id)   # POST /products/:id/matrices
strategy_product_assumption_matrix_path(p, m)   # GET  /products/:id/matrices/:matrix_id
assumption_path(id)                             # PATCH /assumptions/:id
```

### Key New Files

```
app/models/strategy_product.rb
app/models/assumption_matrix.rb
app/models/assumption.rb
app/controllers/strategy_products_controller.rb
app/controllers/assumption_matrices_controller.rb
app/controllers/assumptions_controller.rb
app/views/strategy_products/
app/views/assumption_matrices/
app/views/assumptions/
app/javascript/controllers/form_submit_controller.js
app/javascript/controllers/matrix_sort_controller.js
app/javascript/controllers/confidence_rating_controller.js
spec/models/strategy_product_spec.rb
spec/models/assumption_matrix_spec.rb
spec/models/assumption_spec.rb
spec/requests/strategy_products_spec.rb
spec/requests/assumption_matrices_spec.rb
spec/requests/assumptions_spec.rb
spec/factories/strategy_products.rb
spec/factories/assumption_matrices.rb
spec/factories/assumptions.rb
```

### AI Template

```
Name:          adaptableproduct_assumptions_v1
Model:         gemini-2.5-flash
Max tokens:    2500
Temperature:   0.4
Variables:     product_name, target_customer, strategy, primary_goal
Expected JSON: { "assumptions": [...] }  — 8 to 12 entries
```

### Rules (enforced across all phases)

- No plain JavaScript — Stimulus only
- `turbo_stream.update(...)` never `turbo_stream.replace(...)`
- No hardcoded app name — always `ENV.fetch("APP_NAME", "AdaptableProduct Demo")`
- Never start the Rails server automatically — tell the user
- Never run RSpec automatically — tell the user
- Never add Redis, Sidekiq, or background jobs unless explicitly requested
- No backward-compatibility shims — delete old code, update all callers
