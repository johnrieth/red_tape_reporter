class AddVerificationToReports < ActiveRecord::Migration[8.0]
  def change
    add_column :reports, :verification_token, :string
    add_column :reports, :verified_at, :datetime
    add_index :reports, :verification_token, unique: true
  end
end
