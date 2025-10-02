class AddIssueCategoriesAndOtherFieldsToReports < ActiveRecord::Migration[8.0]
  def change
    add_column :reports, :project_type, :string
    add_column :reports, :location, :string
    add_column :reports, :issue_categories, :text
    add_column :reports, :departments, :text
    add_column :reports, :timeline_impact, :string
    add_column :reports, :financial_impact, :string
  end
end
