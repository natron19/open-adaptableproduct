# Phase 2 — Data Models & Database

**Goal:** Three new models with migrations, associations, validations, computed methods, factories, and passing model specs. No controllers or views yet.

**Prerequisites:** Phase 1 complete. Boilerplate RSpec suite green.

**Spec reference:** `docs/open-adaptableproduct/AdaptableProduct_Demo_Spec_v1.md` §3, §9

---

## Context

This app adds three models on top of the boilerplate's `User`, `AiTemplate`, and `LlmRequest`:

- **StrategyProduct** — the user's input (product name, target customer, strategy, goal)
- **AssumptionMatrix** — one Gemini run against a StrategyProduct; stores the raw response and status
- **Assumption** — one row in the matrix; created in bulk from parsed Gemini JSON

All three use UUID primary keys (the boilerplate's `pgcrypto` extension handles this). All timestamps are `null: false`.

The ownership chain: `User → StrategyProduct → AssumptionMatrix → Assumption`. Every controller scopes through `current_user` to this chain. Never load a record without the scope.

---

## Migrations

### `create_strategy_products`

```ruby
create_table :strategy_products, id: :uuid do |t|
  t.references :user,           null: false, foreign_key: true, type: :uuid
  t.string     :name,           null: false
  t.string     :target_customer, null: false
  t.text       :strategy,       null: false
  t.text       :primary_goal,   null: false
  t.timestamps                  null: false
end
add_index :strategy_products, :user_id
```

### `create_assumption_matrices`

```ruby
create_table :assumption_matrices, id: :uuid do |t|
  t.references :strategy_product, null: false, foreign_key: true, type: :uuid
  t.datetime   :generated_at
  t.text       :gemini_raw
  t.string     :status,          null: false, default: "pending"
  t.timestamps                   null: false
end
add_index :assumption_matrices, :strategy_product_id
add_index :assumption_matrices, :status
```

### `create_assumptions`

```ruby
create_table :assumptions, id: :uuid do |t|
  t.references :assumption_matrix, null: false, foreign_key: true, type: :uuid
  t.text    :statement,    null: false
  t.integer :confidence_ai, null: false
  t.integer :confidence_user
  t.string  :risk,         null: false
  t.string  :category,     null: false
  t.text    :experiment,   null: false
  t.integer :position,     null: false
  t.timestamps             null: false
end
add_index :assumptions, :assumption_matrix_id
add_index :assumptions, :position
```

---

## Models

### `app/models/strategy_product.rb`

```ruby
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
```

### `app/models/assumption_matrix.rb`

```ruby
class AssumptionMatrix < ApplicationRecord
  belongs_to :strategy_product
  has_one :user, through: :strategy_product
  has_many :assumptions, dependent: :destroy

  STATUSES = %w[pending completed failed].freeze

  validates :strategy_product_id, presence: true
  validates :status, inclusion: { in: STATUSES }
end
```

### `app/models/assumption.rb`

```ruby
class Assumption < ApplicationRecord
  belongs_to :assumption_matrix
  has_one :user, through: :assumption_matrix

  RISKS       = %w[low medium high].freeze
  CATEGORIES  = %w[customer market capability economics competitive regulatory].freeze

  validates :statement,    presence: true
  validates :confidence_ai, presence: true, inclusion: { in: 1..5 }
  validates :confidence_user, inclusion: { in: 1..5 }, allow_nil: true
  validates :risk,         presence: true, inclusion: { in: RISKS }
  validates :category,     presence: true, inclusion: { in: CATEGORIES }
  validates :experiment,   presence: true
  validates :position,     presence: true

  def confidence_gap
    return nil if confidence_ai.nil? || confidence_user.nil?
    confidence_ai - confidence_user
  end
end
```

---

## Factories

### `spec/factories/strategy_products.rb`

```ruby
FactoryBot.define do
  factory :strategy_product do
    association :user
    name            { "FieldNote" }
    target_customer { "Solo therapists in private practice billing insurance directly" }
    strategy        { "FieldNote replaces the four-tab workflow most solo therapists use with one weekly view that captures session notes and auto-generates the CPT-coded claim." }
    primary_goal    { "Get to 200 paying solo therapists in 12 months at under $80 CAC." }
  end
end
```

### `spec/factories/assumption_matrices.rb`

```ruby
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
```

### `spec/factories/assumptions.rb`

```ruby
FactoryBot.define do
  factory :assumption do
    association :assumption_matrix
    sequence(:position) { |n| n }
    statement     { "Users will pay $39/month without needing a free trial." }
    confidence_ai { 3 }
    confidence_user { nil }
    risk          { "high" }
    category      { "economics" }
    experiment    { "Offer 10 prospects a direct purchase link before building billing." }
  end
end
```

---

## RSpec Model Specs

### `spec/models/strategy_product_spec.rb`

Cover:
- Presence validations for all four fields
- Length bounds on `target_customer` (10–250), `strategy` (50–2000), `primary_goal` (20–500)
- `belongs_to :user` — invalid without a user
- `has_many :assumption_matrices` with `dependent: :destroy` — deleting a product cascades
- `latest_matrix` scope returns the matrix with the most recent `generated_at`, not just most recently created
- A strategy product for user A is not loadable via `User.find(user_b.id).strategy_products.find(product_a.id)` (raises `ActiveRecord::RecordNotFound`)

### `spec/models/assumption_matrix_spec.rb`

Cover:
- `strategy_product_id` presence required
- `status` must be one of `pending`, `completed`, `failed`
- `belongs_to :strategy_product`
- `has_many :assumptions` with `dependent: :destroy`
- `gemini_raw` is preserved when status is `failed` (not wiped on save)

### `spec/models/assumption_spec.rb`

Cover:
- All required fields (`statement`, `confidence_ai`, `risk`, `category`, `experiment`, `position`)
- `confidence_ai` must be 1–5; values 0 and 6 are invalid
- `confidence_user` is nullable; nil is valid; values outside 1–5 are invalid
- `risk` must be one of `low`, `medium`, `high`
- `category` must be one of the six allowed values
- `confidence_gap` returns `confidence_ai - confidence_user` when both present
- `confidence_gap` returns nil when `confidence_user` is nil

---

## Manual Checks

```
[ ] rails db:migrate runs without errors
[ ] rails console: StrategyProduct.create!(user: User.first, name: "Test", target_customer: "A"*10, strategy: "S"*50, primary_goal: "G"*20) succeeds
[ ] rails console: StrategyProduct.create!(name: "") raises ActiveRecord::RecordInvalid
[ ] rails console: Assumption.new(confidence_ai: 6).valid? returns false
[ ] rails console: Assumption.new(confidence_ai: 3, confidence_user: nil).confidence_gap returns nil
[ ] rails console: Assumption.new(confidence_ai: 3, confidence_user: 1).confidence_gap returns 2
```

---

## RSpec

```bash
bundle exec rspec spec/models/strategy_product_spec.rb spec/models/assumption_matrix_spec.rb spec/models/assumption_spec.rb
```

All three files must be fully green before moving to Phase 3.
