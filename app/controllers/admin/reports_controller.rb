class Admin::ReportsController < Admin::BaseController
  def index
    # Start with base query
    @reports = Report.not_deleted

    # Filter by status
    @filter = params[:filter] || "all"
    @reports = case @filter
    when "pending_review"
                 @reports.pending_review
    when "approved"
                 @reports.approved
    when "unverified"
                 @reports.unverified
    else
                 @reports
    end

    # Filter by email
    if params[:email].present?
      @reports = @reports.where(email: params[:email])
      @filter_email = params[:email]
    end

    # Filter by department
    if params[:department].present?
      @reports = @reports.where("departments LIKE ?", "%\"#{params[:department]}\"%")
      @filter_department = params[:department]
    end

    # Filter by issue category
    if params[:issue_category].present?
      @reports = @reports.where("issue_categories LIKE ?", "%\"#{params[:issue_category]}\"%")
      @filter_issue_category = params[:issue_category]
    end

    # Apply ordering
    @reports = @reports.recent

    # Stats
    @total_approved = Report.approved.count
    @pending_review_count = Report.pending_review.count
    @unverified_count = Report.unverified.count
  end

  def export
    require "csv"

    # Get date range
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 2.months.ago
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today

    # Get approved reports in date range
    @reports = Report.approved
                     .where(verified_at: start_date.beginning_of_day..end_date.end_of_day)
                     .order(verified_at: :desc)

    # Calculate statistics
    @stats = calculate_report_stats(@reports)

    # Log export action for each report (audit trail)
    @reports.each do |report|
      AuditLog.log_action(
        report: report,
        user: Current.user,
        action_type: :report_exported,
        ip_address: request.remote_ip,
        metadata: {
          format: request.format.symbol.to_s,
          date_range: { start: start_date, end: end_date },
          report_count: @reports.count
        }
      )
    end

    respond_to do |format|
      format.csv do
        csv_data = generate_csv(@reports)
        send_data csv_data,
                  filename: "red-tape-reports-#{start_date.strftime('%Y%m%d')}-#{end_date.strftime('%Y%m%d')}.csv",
                  type: "text/csv"
      end

      format.pdf do
        pdf = ReportPdfGenerator.new(
          reports: @reports,
          stats: @stats,
          start_date: start_date,
          end_date: end_date
        ).generate
        send_data pdf.render,
                  filename: "red-tape-report-#{start_date.strftime('%Y%m%d')}-#{end_date.strftime('%Y%m%d')}.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  def show
    @report = Report.not_deleted.find(params[:id])
  end

  def approve
    @report = Report.not_deleted.find(params[:id])
    if @report.approve
      # Log approval action
      AuditLog.log_action(
        report: @report,
        user: Current.user,
        action_type: :report_approved,
        ip_address: request.remote_ip,
        metadata: {
          report_id: @report.id,
          previous_status: @report.status_before_last_save
        }
      )
      redirect_to admin_reports_path(filter: "pending_review"), notice: "Report approved successfully."
    else
      redirect_to admin_report_path(@report), alert: "Failed to approve report."
    end
  end

  def destroy
    @report = Report.not_deleted.find(params[:id])
    if @report.soft_delete
      # Log deletion action
      AuditLog.log_action(
        report: @report,
        user: Current.user,
        action_type: :report_deleted,
        ip_address: request.remote_ip,
        metadata: {
          report_id: @report.id,
          deleted_at: @report.deleted_at
        }
      )
      redirect_to admin_reports_path(filter: "pending_review"), notice: "Report deleted successfully."
    else
      redirect_to admin_report_path(@report), alert: "Failed to delete report."
    end
  end

  private

  def calculate_report_stats(reports)
    {
      total_count: reports.count,
      departments: reports.flat_map(&:departments).compact.tally.sort_by { |_, v| -v }.to_h,
      issue_categories: reports.flat_map(&:issue_categories).compact.tally.sort_by { |_, v| -v }.to_h,
      timeline_impacts: reports.group(:timeline_impact).count,
      project_types: reports.group(:project_type).count
    }
  end

  def generate_csv(reports)
    require "csv"

    CSV.generate(headers: true) do |csv|
      csv << [
        "Report ID",
        "Verified Date",
        "Project Type",
        "Location",
        "Project Description",
        "Issue Description",
        "Timeline Impact",
        "Financial Impact",
        "Issue Categories",
        "Departments",
        "Solution Ideas"
      ]

      reports.each do |report|
        csv << [
          report.id,
          report.verified_at&.strftime("%Y-%m-%d"),
          report.project_type,
          report.location,
          report.project_description,
          report.issue_description,
          report.timeline_impact,
          report.financial_impact,
          report.issue_categories.join(", "),
          report.departments.join(", "),
          report.solution_ideas
        ]
      end
    end
  end

end
