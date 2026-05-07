class CreateAssumptionMatrices < ActiveRecord::Migration[8.1]
  def change
    create_table :assumption_matrices, id: :uuid do |t|
      t.references :strategy_product, null: false, foreign_key: true, type: :uuid
      t.datetime :generated_at
      t.text     :gemini_raw
      t.string   :status, null: false, default: "pending"
      t.timestamps null: false
    end

    add_index :assumption_matrices, :status
  end
end
