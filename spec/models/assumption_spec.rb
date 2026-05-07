require "rails_helper"

RSpec.describe Assumption, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:assumption)).to be_valid
    end

    it "requires statement" do
      expect(build(:assumption, statement: nil)).not_to be_valid
    end

    it "requires confidence_ai" do
      expect(build(:assumption, confidence_ai: nil)).not_to be_valid
    end

    it "requires confidence_ai to be between 1 and 5" do
      expect(build(:assumption, confidence_ai: 0)).not_to be_valid
      expect(build(:assumption, confidence_ai: 6)).not_to be_valid
      expect(build(:assumption, confidence_ai: 1)).to be_valid
      expect(build(:assumption, confidence_ai: 5)).to be_valid
    end

    it "allows confidence_user to be nil" do
      expect(build(:assumption, confidence_user: nil)).to be_valid
    end

    it "requires confidence_user to be between 1 and 5 when present" do
      expect(build(:assumption, confidence_user: 0)).not_to be_valid
      expect(build(:assumption, confidence_user: 6)).not_to be_valid
      expect(build(:assumption, confidence_user: 1)).to be_valid
      expect(build(:assumption, confidence_user: 5)).to be_valid
    end

    it "requires risk" do
      expect(build(:assumption, risk: nil)).not_to be_valid
    end

    it "requires risk to be a known value" do
      expect(build(:assumption, risk: "extreme")).not_to be_valid
      expect(build(:assumption, risk: "low")).to be_valid
      expect(build(:assumption, risk: "medium")).to be_valid
      expect(build(:assumption, risk: "high")).to be_valid
    end

    it "requires category" do
      expect(build(:assumption, category: nil)).not_to be_valid
    end

    it "requires category to be a known value" do
      expect(build(:assumption, category: "unknown")).not_to be_valid
      %w[customer market capability economics competitive regulatory].each do |cat|
        expect(build(:assumption, category: cat)).to be_valid
      end
    end

    it "requires experiment" do
      expect(build(:assumption, experiment: nil)).not_to be_valid
    end

    it "requires position" do
      expect(build(:assumption, position: nil)).not_to be_valid
    end
  end

  describe "#confidence_gap" do
    it "returns the difference between confidence_ai and confidence_user" do
      assumption = build(:assumption, confidence_ai: 4, confidence_user: 2)
      expect(assumption.confidence_gap).to eq(2)
    end

    it "returns a negative value when user is more confident than AI" do
      assumption = build(:assumption, confidence_ai: 2, confidence_user: 4)
      expect(assumption.confidence_gap).to eq(-2)
    end

    it "returns zero when both confidences are equal" do
      assumption = build(:assumption, confidence_ai: 3, confidence_user: 3)
      expect(assumption.confidence_gap).to eq(0)
    end

    it "returns nil when confidence_user is nil" do
      assumption = build(:assumption, confidence_ai: 3, confidence_user: nil)
      expect(assumption.confidence_gap).to be_nil
    end
  end
end
