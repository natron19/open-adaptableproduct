class Assumption < ApplicationRecord
  belongs_to :assumption_matrix
  has_one :user, through: :assumption_matrix

  RISKS      = %w[low medium high].freeze
  CATEGORIES = %w[customer market capability economics competitive regulatory].freeze

  validates :statement,     presence: true
  validates :confidence_ai, presence: true, inclusion: { in: 1..5 }
  validates :confidence_user, inclusion: { in: 1..5 }, allow_nil: true
  validates :risk,          presence: true, inclusion: { in: RISKS }
  validates :category,      presence: true, inclusion: { in: CATEGORIES }
  validates :experiment,    presence: true
  validates :position,      presence: true

  def confidence_gap
    return nil if confidence_ai.nil? || confidence_user.nil?
    confidence_ai - confidence_user
  end
end
