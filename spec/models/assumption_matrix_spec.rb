require "rails_helper"

RSpec.describe AssumptionMatrix, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:assumption_matrix)).to be_valid
    end

    it "requires a strategy_product" do
      expect(build(:assumption_matrix, strategy_product: nil)).not_to be_valid
    end

    it "requires status to be a known value" do
      expect(build(:assumption_matrix, status: "unknown")).not_to be_valid
    end

    it "accepts pending status" do
      expect(build(:assumption_matrix, status: "pending")).to be_valid
    end

    it "accepts completed status" do
      expect(build(:assumption_matrix, status: "completed")).to be_valid
    end

    it "accepts failed status" do
      expect(build(:assumption_matrix, status: "failed")).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a strategy_product" do
      matrix = create(:assumption_matrix)
      expect(matrix.strategy_product).to be_a(StrategyProduct)
    end

    it "has a user through strategy_product" do
      matrix = create(:assumption_matrix)
      expect(matrix.user).to be_a(User)
    end

    it "destroys associated assumptions when deleted" do
      matrix = create(:assumption_matrix)
      create(:assumption, assumption_matrix: matrix)
      expect { matrix.destroy }.to change(Assumption, :count).by(-1)
    end
  end

  describe "gemini_raw on failure" do
    it "preserves gemini_raw when status is failed" do
      matrix = create(:assumption_matrix, :failed)
      matrix.reload
      expect(matrix.gemini_raw).to eq("malformed response")
      expect(matrix.status).to eq("failed")
    end
  end
end
