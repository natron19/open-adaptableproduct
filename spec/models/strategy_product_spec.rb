require "rails_helper"

RSpec.describe StrategyProduct, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:strategy_product)).to be_valid
    end

    it "requires name" do
      expect(build(:strategy_product, name: nil)).not_to be_valid
    end

    it "requires target_customer" do
      expect(build(:strategy_product, target_customer: nil)).not_to be_valid
    end

    it "requires target_customer to be at least 10 characters" do
      expect(build(:strategy_product, target_customer: "A" * 9)).not_to be_valid
    end

    it "requires target_customer to be at most 250 characters" do
      expect(build(:strategy_product, target_customer: "A" * 251)).not_to be_valid
    end

    it "requires strategy" do
      expect(build(:strategy_product, strategy: nil)).not_to be_valid
    end

    it "requires strategy to be at least 50 characters" do
      expect(build(:strategy_product, strategy: "A" * 49)).not_to be_valid
    end

    it "requires strategy to be at most 2000 characters" do
      expect(build(:strategy_product, strategy: "A" * 2001)).not_to be_valid
    end

    it "requires primary_goal" do
      expect(build(:strategy_product, primary_goal: nil)).not_to be_valid
    end

    it "requires primary_goal to be at least 20 characters" do
      expect(build(:strategy_product, primary_goal: "A" * 19)).not_to be_valid
    end

    it "requires primary_goal to be at most 500 characters" do
      expect(build(:strategy_product, primary_goal: "A" * 501)).not_to be_valid
    end
  end

  describe "associations" do
    it "belongs to a user" do
      expect(build(:strategy_product, user: nil)).not_to be_valid
    end

    it "destroys associated assumption_matrices when deleted" do
      product = create(:strategy_product)
      create(:assumption_matrix, strategy_product: product)
      expect { product.destroy }.to change(AssumptionMatrix, :count).by(-1)
    end
  end

  describe "#latest_matrix" do
    it "returns the matrix with the most recent generated_at" do
      product = create(:strategy_product)
      older = create(:assumption_matrix, :completed, strategy_product: product,
                     generated_at: 1.hour.ago)
      newer = create(:assumption_matrix, :completed, strategy_product: product,
                     generated_at: 1.minute.ago)
      expect(product.latest_matrix).to eq(newer)
    end

    it "returns nil when there are no matrices" do
      product = create(:strategy_product)
      expect(product.latest_matrix).to be_nil
    end
  end

  describe "user scoping" do
    it "cannot be found via a different user's scope" do
      product = create(:strategy_product)
      other_user = create(:user)
      expect {
        other_user.strategy_products.find(product.id)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
