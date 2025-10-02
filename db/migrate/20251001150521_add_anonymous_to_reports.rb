class AddAnonymousToReports < ActiveRecord::Migration[8.0]
  def change
    add_column :reports, :anonymous, :boolean, default: false, null: false
  end
end
