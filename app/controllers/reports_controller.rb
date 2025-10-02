# app/controllers/reports_controller.rb
class ReportsController < ApplicationController
  allow_unauthenticated_access
  
  def new
    @report = Report.new
  end

  def create
    @report = Report.new(report_params)
    @report.anonymous = report_params[:name].blank?

    if @report.save
      ReportMailer.verification(@report).deliver_later
      redirect_to success_reports_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def success
    # Confirmation page
  end

  private

  def report_params
    params.require(:report).permit(
      :name, 
      :email, 
      :project_type,
      :project_description, 
      :location,
      :issue_description,
      :timeline_impact,
      :financial_impact,
      issue_categories: [],
      departments: []
    )
  end
end