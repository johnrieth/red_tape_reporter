class CreateSupports < ActiveRecord::Migration[8.0]
  def change
    create_table :supports do |t|
      t.references :issue, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.integer :visibility
      t.string :anonymity_token
      t.decimal :estimated_cost
      t.string :project_reference

      t.timestamps
    end
  end
end
