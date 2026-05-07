class AssumptionMatrix < ApplicationRecord
  belongs_to :strategy_product
  has_one :user, through: :strategy_product
  has_many :assumptions, dependent: :destroy

  STATUSES = %w[pending completed failed].freeze

  validates :status, inclusion: { in: STATUSES }
end
