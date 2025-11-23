# app/controllers/reports_controller.rb
class ReportsController < ApplicationController
  allow_unauthenticated_access

  def index
    # Landing page - only show approved reports count
    @verified_reports_count = Rails.cache.fetch("reports/approved_count", expires_in: 10.minutes) do
      Report.approved.count
    end
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
    # HTTP caching - return 304 Not Modified if content hasn't changed
    cache_key = Rails.cache.fetch("reports/transparency_cache_key", expires_in: 1.hour) { Time.current.to_i }
    return if stale?(etag: cache_key, public: true)

    # Cache all transparency stats for 1 hour (invalidated when reports are approved)
    stats = Rails.cache.fetch("reports/transparency_stats", expires_in: 1.hour) do
      reports = Report.approved

      total_count = reports.count
      avg_days = if total_count > 0
        (reports.sum { |r| (Date.today - r.verified_at.to_date).to_i } / total_count.to_f).round
      end

      {
        total_count: total_count,
        department_stats: reports.flat_map(&:departments).compact.tally.sort_by { |_, v| -v },
        issue_stats: reports.flat_map(&:issue_categories).compact.tally.sort_by { |_, v| -v },
        timeline_stats: reports.group(:timeline_impact).count.reject { |k, _| k.blank? },
        project_stats: reports.group(:project_type).count.reject { |k, _| k.blank? }.sort_by { |_, v| -v },
        reports_with_financial_impact: reports.where.not(financial_impact: [ nil, "" ]).count,
        average_days_old: avg_days
      }
    end

    @total_count = stats[:total_count]
    @department_stats = stats[:department_stats]
    @issue_stats = stats[:issue_stats]
    @timeline_stats = stats[:timeline_stats]
    @project_stats = stats[:project_stats]
    @reports_with_financial_impact = stats[:reports_with_financial_impact]
    @average_days_old = stats[:average_days_old]
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
