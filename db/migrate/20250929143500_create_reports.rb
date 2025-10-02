class CreateReports < ActiveRecord::Migration[8.0]
  def change
    create_table :reports do |t|
      t.string :name
      t.string :email
      t.text :project_description
      t.text :issue_description
      t.string :status
      t.string :string

      t.timestamps
    end
  end
end
