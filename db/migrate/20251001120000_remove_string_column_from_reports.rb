class RemoveStringColumnFromReports < ActiveRecord::Migration[8.0]
  def change
    # Remove the accidental `string` column if it exists. This is safe to run
    # in environments where the column may already have been removed.
    if column_exists?(:reports, :string)
      remove_column :reports, :string, :string
    end
  end
end
