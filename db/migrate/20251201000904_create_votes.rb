class CreateVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :votes do |t|
      t.references :report, null: false, foreign_key: true
      t.string :voter_token, null: false

      t.timestamps
    end

    # Prevent duplicate votes from same token on same report
    add_index :votes, [ :report_id, :voter_token ], unique: true
  end
end
