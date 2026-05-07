require "rails_helper"

RSpec.describe "AssumptionMatrices", type: :request do
  let(:user)    { create(:user) }
  let(:other)   { create(:user) }
  let(:product) { create(:strategy_product, user: user) }

  let(:valid_response) do
    { "assumptions" => Array.new(8) do |i|
      {
        "statement"     => "Assumption #{i + 1}: users will adopt this product.",
        "confidence_ai" => 3,
        "risk"          => "high",
        "category"      => "customer",
        "experiment"    => "Run 5 customer interviews before building."
      }
    end }.to_json
  end

  describe "POST /products/:strategy_product_id/matrices" do
    context "when not signed in" do
      it "redirects to sign in" do
        post strategy_product_assumption_matrices_path(product)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in as the owner" do
      before do
        sign_in_as(user)
        gemini_returns(valid_response)
      end

      it "calls GeminiService with the correct template and variables" do
        expect(GeminiService).to receive(:generate).with(
          template:  "adaptableproduct_assumptions_v1",
          variables: {
            product_name:    product.name,
            target_customer: product.target_customer,
            strategy:        product.strategy,
            primary_goal:    product.primary_goal
          }
        ).and_return(valid_response)

        post strategy_product_assumption_matrices_path(product)
      end

      it "creates a completed AssumptionMatrix" do
        expect {
          post strategy_product_assumption_matrices_path(product)
        }.to change(AssumptionMatrix, :count).by(1)

        expect(AssumptionMatrix.last.status).to eq("completed")
      end

      it "creates 8 Assumption rows" do
        expect {
          post strategy_product_assumption_matrices_path(product)
        }.to change(Assumption, :count).by(8)
      end

      it "stores gemini_raw on the matrix" do
        post strategy_product_assumption_matrices_path(product)
        expect(AssumptionMatrix.last.gemini_raw).to eq(valid_response)
      end

      it "redirects to the matrix show page" do
        post strategy_product_assumption_matrices_path(product)
        matrix = AssumptionMatrix.last
        expect(response).to redirect_to(
          strategy_product_assumption_matrix_path(product, matrix)
        )
      end
    end

    context "when Gemini returns malformed JSON" do
      before do
        sign_in_as(user)
        gemini_returns("this is not json at all")
      end

      it "creates a failed AssumptionMatrix" do
        expect {
          post strategy_product_assumption_matrices_path(product)
        }.to change(AssumptionMatrix, :count).by(1)

        expect(AssumptionMatrix.last.status).to eq("failed")
      end

      it "stores the raw response on the failed matrix" do
        post strategy_product_assumption_matrices_path(product)
        expect(AssumptionMatrix.last.gemini_raw).to eq("this is not json at all")
      end

      it "creates no Assumption rows" do
        expect {
          post strategy_product_assumption_matrices_path(product)
        }.not_to change(Assumption, :count)
      end

      it "redirects to the product show page" do
        post strategy_product_assumption_matrices_path(product)
        expect(response).to redirect_to(strategy_product_path(product))
      end
    end

    context "when Gemini returns valid JSON but wrong number of assumptions" do
      before do
        sign_in_as(user)
        too_few = { "assumptions" => Array.new(3) {
          { "statement" => "x", "confidence_ai" => 3, "risk" => "low",
            "category" => "market", "experiment" => "test" }
        } }.to_json
        gemini_returns(too_few)
      end

      it "creates a failed matrix and redirects to product show" do
        post strategy_product_assumption_matrices_path(product)
        expect(AssumptionMatrix.last.status).to eq("failed")
        expect(response).to redirect_to(strategy_product_path(product))
      end
    end

    context "when BudgetExceededError is raised" do
      before do
        sign_in_as(user)
        gemini_raises(GeminiService::BudgetExceededError)
      end

      it "does not create a matrix" do
        expect {
          post strategy_product_assumption_matrices_path(product)
        }.not_to change(AssumptionMatrix, :count)
      end

      it "renders the budget-exceeded error message" do
        post strategy_product_assumption_matrices_path(product)
        expect(response.body).to include("daily AI request limit")
      end
    end

    context "when TimeoutError is raised" do
      before do
        sign_in_as(user)
        gemini_raises(GeminiService::TimeoutError)
      end

      it "does not create a matrix" do
        expect {
          post strategy_product_assumption_matrices_path(product)
        }.not_to change(AssumptionMatrix, :count)
      end

      it "renders the timeout error message" do
        post strategy_product_assumption_matrices_path(product)
        expect(response.body).to include("took too long")
      end
    end

    context "when signed in as a different user" do
      it "returns 404" do
        sign_in_as(other)
        post strategy_product_assumption_matrices_path(product)
        expect(response).to have_http_status(:not_found)
      end

      it "creates no matrix" do
        expect {
          sign_in_as(other)
          post strategy_product_assumption_matrices_path(product)
        }.not_to change(AssumptionMatrix, :count)
      end
    end
  end

  describe "GET /products/:strategy_product_id/matrices/:id" do
    let(:matrix) { create(:assumption_matrix, :completed, strategy_product: product) }

    context "when signed in as the owner" do
      it "returns 200" do
        sign_in_as(user)
        get strategy_product_assumption_matrix_path(product, matrix)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when signed in as a different user" do
      it "returns 404" do
        sign_in_as(other)
        get strategy_product_assumption_matrix_path(product, matrix)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
