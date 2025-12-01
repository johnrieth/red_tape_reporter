class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.references :report, null: false, foreign_key: true
      t.text :content, null: false
      t.string :commenter_token, null: false

      t.timestamps
    end

    # Index for efficient queries
    add_index :comments, [ :report_id, :created_at ]
  end
end
