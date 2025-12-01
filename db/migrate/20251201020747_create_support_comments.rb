class CreateSupportComments < ActiveRecord::Migration[8.0]
  def change
    create_table :support_comments do |t|
      t.references :support, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.text :content
      t.integer :visibility
      t.json :impact_data

      t.timestamps
    end
  end
end
