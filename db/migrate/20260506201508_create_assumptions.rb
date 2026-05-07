class CreateAssumptions < ActiveRecord::Migration[8.1]
  def change
    create_table :assumptions, id: :uuid do |t|
      t.references :assumption_matrix, null: false, foreign_key: true, type: :uuid
      t.text    :statement,     null: false
      t.integer :confidence_ai, null: false
      t.integer :confidence_user
      t.string  :risk,          null: false
      t.string  :category,      null: false
      t.text    :experiment,    null: false
      t.integer :position,      null: false
      t.timestamps null: false
    end

    add_index :assumptions, :position
  end
end
