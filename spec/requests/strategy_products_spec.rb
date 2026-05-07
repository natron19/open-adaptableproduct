require "rails_helper"

RSpec.describe "StrategyProducts", type: :request do
  let(:user)    { create(:user) }
  let(:other)   { create(:user) }
  let!(:product) { create(:strategy_product, user: user) }

  describe "GET /products" do
    context "when not signed in" do
      it "redirects to sign in" do
        get strategy_products_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in" do
      before { sign_in_as(user) }

      it "returns 200" do
        get strategy_products_path
        expect(response).to have_http_status(:ok)
      end

      it "only shows the current user's products" do
        other_product = create(:strategy_product, user: other, name: "RivalProduct")
        get strategy_products_path
        expect(response.body).to include(product.name)
        expect(response.body).not_to include(other_product.name)
      end
    end
  end

  describe "GET /products/new" do
    context "when not signed in" do
      it "redirects to sign in" do
        get new_strategy_product_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in" do
      it "returns 200" do
        sign_in_as(user)
        get new_strategy_product_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /products" do
    let(:valid_params) do
      { strategy_product: {
        name:            "TestProduct",
        target_customer: "Freelance designers billing clients",
        strategy:        "We replace the four tools most freelancers juggle with one timeline that tracks project status and auto-sends invoices at milestones.",
        primary_goal:    "Reach 100 paying freelancers in 6 months at under $60 CAC."
      } }
    end

    context "when not signed in" do
      it "redirects to sign in" do
        post strategy_products_path, params: valid_params
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in with valid params" do
      before { sign_in_as(user) }

      it "creates a product and redirects to it" do
        expect {
          post strategy_products_path, params: valid_params
        }.to change(StrategyProduct, :count).by(1)
        new_product = user.strategy_products.find_by!(name: "TestProduct")
        expect(response).to redirect_to(strategy_product_path(new_product))
      end

      it "assigns the product to the current user" do
        post strategy_products_path, params: valid_params
        expect(StrategyProduct.last.user).to eq(user)
      end
    end

    context "when signed in with invalid params" do
      before { sign_in_as(user) }

      it "returns 422 and re-renders the form" do
        post strategy_products_path,
             params: { strategy_product: { name: "", target_customer: "", strategy: "", primary_goal: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "ignores unknown params" do
        post strategy_products_path,
             params: { strategy_product: valid_params[:strategy_product].merge(admin: true) }
        expect(StrategyProduct.last).to be_present
      end
    end
  end

  describe "GET /products/:id" do
    context "when not signed in" do
      it "redirects to sign in" do
        get strategy_product_path(product)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in as the owner" do
      it "returns 200" do
        sign_in_as(user)
        get strategy_product_path(product)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when signed in as a different user" do
      it "returns 404" do
        sign_in_as(other)
        get strategy_product_path(product)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /products/:id/edit" do
    context "when signed in as the owner" do
      it "returns 200" do
        sign_in_as(user)
        get edit_strategy_product_path(product)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when signed in as a different user" do
      it "returns 404" do
        sign_in_as(other)
        get edit_strategy_product_path(product)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /products/:id" do
    context "when signed in as the owner with valid params" do
      before { sign_in_as(user) }

      it "updates the product and redirects" do
        patch strategy_product_path(product),
              params: { strategy_product: { name: "Updated Name" } }
        expect(product.reload.name).to eq("Updated Name")
        expect(response).to redirect_to(strategy_product_path(product))
      end
    end

    context "when signed in as the owner with invalid params" do
      it "returns 422" do
        sign_in_as(user)
        patch strategy_product_path(product),
              params: { strategy_product: { name: "", strategy: "x" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when signed in as a different user" do
      it "returns 404" do
        sign_in_as(other)
        patch strategy_product_path(product),
              params: { strategy_product: { name: "Hacked" } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /products/:id" do
    context "when signed in as the owner" do
      before { sign_in_as(user) }

      it "deletes the product and redirects to index" do
        expect {
          delete strategy_product_path(product)
        }.to change(StrategyProduct, :count).by(-1)
        expect(response).to redirect_to(strategy_products_path)
      end
    end

    context "when signed in as a different user" do
      it "returns 404 and does not delete" do
        sign_in_as(other)
        expect {
          delete strategy_product_path(product)
        }.not_to change(StrategyProduct, :count)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
