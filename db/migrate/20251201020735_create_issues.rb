class CreateIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :issues do |t|
      t.string :title
      t.text :description
      t.integer :category
      t.integer :status
      t.references :submitted_by, null: false, foreign_key: { to_table: :users }
      t.boolean :is_public
      t.json :metadata

      t.timestamps
    end
  end
end
