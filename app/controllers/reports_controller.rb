# app/controllers/reports_controller.rb
class ReportsController < ApplicationController
  allow_unauthenticated_access

  def index
    # Landing page - only show approved reports count
    @verified_reports_count = Report.approved.count
  end

  def new
    @report = Report.new
  end

  def create
    @report = Report.new(report_params)
    @report.anonymous = true

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

  def transparency
    # Get all approved reports for analysis
    @reports = Report.approved

    # Total count
    @total_count = @reports.count

    # Department breakdown (sorted by count)
    @department_stats = @reports.flat_map(&:departments).compact.tally.sort_by { |_, v| -v }

    # Issue category breakdown (sorted by count)
    @issue_stats = @reports.flat_map(&:issue_categories).compact.tally.sort_by { |_, v| -v }

    # Timeline impact breakdown
    @timeline_stats = @reports.group(:timeline_impact).count.reject { |k, _| k.blank? }

    # Project type breakdown
    @project_stats = @reports.group(:project_type).count.reject { |k, _| k.blank? }.sort_by { |_, v| -v }

    # Financial impact - count how many reports mention financial impact
    @reports_with_financial_impact = @reports.where.not(financial_impact: [ nil, "" ]).count

    # Calculate average days since verification (to show data freshness)
    if @total_count > 0
      @average_days_old = (@reports.sum { |r| (Date.today - r.verified_at.to_date).to_i } / @total_count.to_f).round
    end
  end

  private

  def report_params
    params.require(:report).permit(
      :email,
      :project_type,
      :project_description,
      :location,
      :issue_description,
      :timeline_impact,
      :financial_impact,
      :solution_ideas,
      issue_categories: [],
      departments: []
    )
  end
end
