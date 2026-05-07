FactoryBot.define do
  factory :assumption_matrix do
    association :strategy_product
    status       { "pending" }
    generated_at { nil }
    gemini_raw   { nil }

    trait :completed do
      status       { "completed" }
      generated_at { Time.current }
      gemini_raw   { '{"assumptions":[]}' }
    end

    trait :failed do
      status     { "failed" }
      gemini_raw { "malformed response" }
    end
  end
end
