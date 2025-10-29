class AddSolutionIdeasToReports < ActiveRecord::Migration[8.0]
  def change
    add_column :reports, :solution_ideas, :text
  end
end
