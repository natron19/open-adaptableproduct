class StrategyProduct < ApplicationRecord
  belongs_to :user
  has_many :assumption_matrices, dependent: :destroy
  has_one :latest_matrix,
          -> { order(generated_at: :desc) },
          class_name: "AssumptionMatrix"

  validates :name,            presence: true
  validates :target_customer, presence: true, length: { in: 10..250 }
  validates :strategy,        presence: true, length: { in: 50..2000 }
  validates :primary_goal,    presence: true, length: { in: 20..500 }
end
