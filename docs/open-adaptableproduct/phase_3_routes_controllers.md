# Phase 3 — Routes & Controller Skeletons

**Goal:** All routes registered and named helpers working. Controller files exist with all actions. Views are not needed yet — actions can raise or redirect to a placeholder.

**Prerequisites:** Phase 2 complete. All three model specs green.

**Spec reference:** `docs/open-adaptableproduct/AdaptableProduct_Demo_Spec_v1.md` §4, §5

---

## Context

The boilerplate already has routes for auth, admin, and health. This phase adds three new resource controllers. The dashboard route (`/dashboard`) is rewired to `strategy_products#index` so the logged-in home page becomes the products list.

All three controllers must:
- Inherit from `ApplicationController` (enforces `require_authentication`)
- Scope every finder through `current_user` — never load a record directly by ID
- Return 404 (not 403) when a user tries to access another user's record

---

## Routes

Add to `config/routes.rb` inside the authenticated scope (before the admin namespace):

```ruby
get "/dashboard", to: "strategy_products#index"   # rewire dashboard

resources :strategy_products, path: :products do
  resources :assumption_matrices,
            only: %i[create show],
            path: :matrices,
            as: :assumption_matrices
end

resources :assumptions, only: %i[update]
```

This produces the following named helpers — verify them with `rails routes | grep products`:

```
strategy_products_path                          # GET  /products
new_strategy_product_path                       # GET  /products/new
strategy_product_path(id)                       # GET  /products/:id
edit_strategy_product_path(id)                  # GET  /products/:id/edit
strategy_product_assumption_matrices_path(sp)   # POST /products/:id/matrices
strategy_product_assumption_matrix_path(sp, m)  # GET  /products/:id/matrices/:id
assumption_path(id)                             # PATCH /assumptions/:id
```

---

## Controllers

### `app/controllers/strategy_products_controller.rb`

Seven standard RESTful actions. Scope all finders to `current_user.strategy_products`.

```ruby
class StrategyProductsController < ApplicationController
  before_action :set_strategy_product, only: %i[show edit update destroy]

  def index
    @strategy_products = current_user.strategy_products.order(created_at: :desc)
  end

  def show; end

  def new
    @strategy_product = current_user.strategy_products.build
  end

  def create
    @strategy_product = current_user.strategy_products.build(strategy_product_params)
    if @strategy_product.save
      redirect_to @strategy_product
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @strategy_product.update(strategy_product_params)
      redirect_to @strategy_product
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @strategy_product.destroy
    redirect_to strategy_products_path
  end

  private

  def set_strategy_product
    @strategy_product = current_user.strategy_products.find(params[:id])
  end

  def strategy_product_params
    params.require(:strategy_product).permit(:name, :target_customer, :strategy, :primary_goal)
  end
end
```

### `app/controllers/assumption_matrices_controller.rb`

Two actions. The `create` action is the Gemini-calling one — leave it as a stub (redirect or raise `NotImplementedError`) until Phase 5.

```ruby
class AssumptionMatricesController < ApplicationController
  before_action :set_strategy_product

  def show
    @matrix = @strategy_product.assumption_matrices.find(params[:id])
  end

  def create
    # Gemini integration added in Phase 5
    redirect_to @strategy_product, notice: "AI integration coming in Phase 5."
  end

  private

  def set_strategy_product
    @strategy_product = current_user.strategy_products.find(params[:strategy_product_id])
  end
end
```

### `app/controllers/assumptions_controller.rb`

One action. The full scope chain prevents cross-user access. Stub the response for now — Turbo Stream response is added in Phase 6.

```ruby
class AssumptionsController < ApplicationController
  def update
    @assumption = current_user.strategy_products
                              .joins(assumption_matrices: :assumptions)
                              .merge(Assumption.where(id: params[:id]))
                              .first
    raise ActiveRecord::RecordNotFound unless @assumption

    @assumption.update(assumption_params)
    # Turbo Stream response added in Phase 6
    head :ok
  end

  private

  def assumption_params
    params.require(:assumption).permit(:confidence_user)
  end
end
```

---

## Manual Checks

```
[ ] rails routes | grep products shows all expected routes with correct names
[ ] rails routes | grep assumption shows assumption_path helper
[ ] GET /products redirects to /sign_in when not authenticated
[ ] GET /products returns 200 when signed in (even with a missing template error — that confirms routing works)
[ ] rails console: app.strategy_products_path returns "/products"
[ ] rails console: app.strategy_product_path("some-uuid") returns "/products/some-uuid"
```

---

## RSpec

No new request specs in this phase. Run the full suite to confirm routing doesn't break boilerplate specs:

```bash
bundle exec rspec
```

All existing specs must remain green.
