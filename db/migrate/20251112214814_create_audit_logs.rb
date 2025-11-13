class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :report, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :action_type, null: false
      t.string :ip_address
      t.text :metadata

      t.timestamps
    end

    add_index :audit_logs, [ :report_id, :created_at ]
    add_index :audit_logs, [ :user_id, :created_at ]
    add_index :audit_logs, :action_type
  end
end
