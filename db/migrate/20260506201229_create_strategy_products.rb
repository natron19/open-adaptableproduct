class CreateStrategyProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :strategy_products, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :name,            null: false
      t.string :target_customer, null: false
      t.text   :strategy,        null: false
      t.text   :primary_goal,    null: false
      t.timestamps null: false
    end
  end
end
