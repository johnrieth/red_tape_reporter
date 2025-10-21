class AddApprovalAndDeletionToReports < ActiveRecord::Migration[8.0]
  def change
    add_column :reports, :approved_at, :datetime
    add_column :reports, :deleted_at, :datetime
    add_index :reports, :deleted_at
    add_index :reports, :approved_at
  end
end
