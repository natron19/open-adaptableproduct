require "rails_helper"

RSpec.describe "Assumptions", type: :request do
  let(:user)       { create(:user) }
  let(:other)      { create(:user) }
  let(:product)    { create(:strategy_product, user: user) }
  let(:matrix)     { create(:assumption_matrix, :completed, strategy_product: product) }
  let(:assumption) { create(:assumption, assumption_matrix: matrix, confidence_user: nil) }

  describe "PATCH /assumptions/:id" do
    context "when not signed in" do
      it "redirects to sign in" do
        patch assumption_path(assumption), params: { assumption: { confidence_user: 3 } }
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in as the owner" do
      before { sign_in_as(user) }

      it "updates confidence_user" do
        patch assumption_path(assumption), params: { assumption: { confidence_user: 4 } }
        expect(assumption.reload.confidence_user).to eq(4)
      end

      it "returns a Turbo Stream response" do
        patch assumption_path(assumption), params: { assumption: { confidence_user: 4 } }
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end

      it "includes a turbo-stream update for the confidence frame" do
        patch assumption_path(assumption), params: { assumption: { confidence_user: 4 } }
        expect(response.body).to include("assumption_#{assumption.id}_confidence")
      end

      it "includes a turbo-stream update for the gap frame" do
        patch assumption_path(assumption), params: { assumption: { confidence_user: 4 } }
        expect(response.body).to include("assumption_#{assumption.id}_gap")
      end

      it "returns 422 for confidence_user of 0" do
        patch assumption_path(assumption), params: { assumption: { confidence_user: 0 } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns 422 for confidence_user of 6" do
        patch assumption_path(assumption), params: { assumption: { confidence_user: 6 } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "accepts the boundary values 1 and 5" do
        patch assumption_path(assumption), params: { assumption: { confidence_user: 1 } }
        expect(assumption.reload.confidence_user).to eq(1)

        patch assumption_path(assumption), params: { assumption: { confidence_user: 5 } }
        expect(assumption.reload.confidence_user).to eq(5)
      end
    end

    context "when signed in as a different user" do
      it "returns 404" do
        sign_in_as(other)
        patch assumption_path(assumption), params: { assumption: { confidence_user: 3 } }
        expect(response).to have_http_status(:not_found)
      end

      it "does not update the assumption" do
        sign_in_as(other)
        patch assumption_path(assumption), params: { assumption: { confidence_user: 3 } }
        expect(assumption.reload.confidence_user).to be_nil
      end
    end
  end
end
