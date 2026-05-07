FactoryBot.define do
  factory :assumption do
    association :assumption_matrix
    sequence(:position) { |n| n }
    statement      { "Users will pay $39/month without needing a free trial." }
    confidence_ai  { 3 }
    confidence_user { nil }
    risk           { "high" }
    category       { "economics" }
    experiment     { "Offer 10 prospects a direct purchase link before building billing infrastructure." }
  end
end
