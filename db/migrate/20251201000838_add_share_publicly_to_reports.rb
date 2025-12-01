class AddSharePubliclyToReports < ActiveRecord::Migration[8.0]
  def change
    add_column :reports, :share_publicly, :boolean, default: false, null: false
  end
end
