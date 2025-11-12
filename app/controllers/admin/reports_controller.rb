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
    require "prawn"
    require "prawn/table"

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
        pdf = generate_pdf(@reports, @stats, start_date, end_date)
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

  def generate_pdf(reports, stats, start_date, end_date)
    require "prawn"
    require "prawn/table"

    Prawn::Document.new(page_size: "LETTER", margin: 50) do |pdf|
      # Title
      pdf.font "Helvetica", size: 24, style: :bold
      pdf.text "Red Tape LA Report", align: :center, color: "0b3d66"

      pdf.font "Helvetica", size: 12
      pdf.text "#{start_date.strftime('%B %d, %Y')} - #{end_date.strftime('%B %d, %Y')}", align: :center
      pdf.move_down 30

      # Executive Summary
      pdf.font "Helvetica", size: 16, style: :bold
      pdf.text "Executive Summary"
      pdf.move_down 10

      pdf.font "Helvetica", size: 11
      pdf.text "This report documents #{stats[:total_count]} verified reports of bureaucratic barriers in LA's building process, collected between #{start_date.strftime('%B %d, %Y')} and #{end_date.strftime('%B %d, %Y')}."
      pdf.move_down 20

      # Statistics Section
      pdf.font "Helvetica", size: 14, style: :bold
      pdf.text "Key Statistics"
      pdf.move_down 10

      # Most common departments
      if stats[:departments].any?
        pdf.font "Helvetica", size: 12, style: :bold
        pdf.text "Most Frequently Mentioned Departments:"
        pdf.font "Helvetica", size: 10
        stats[:departments].first(5).each do |dept, count|
          pdf.text "• #{dept}: #{count} reports"
        end
        pdf.move_down 15
      end

      # Most common issues
      if stats[:issue_categories].any?
        pdf.font "Helvetica", size: 12, style: :bold
        pdf.text "Most Common Issue Categories:"
        pdf.font "Helvetica", size: 10
        stats[:issue_categories].first(5).each do |issue, count|
          pdf.text "• #{issue}: #{count} reports"
        end
        pdf.move_down 15
      end

      # Timeline impacts
      if stats[:timeline_impacts].any?
        pdf.font "Helvetica", size: 12, style: :bold
        pdf.text "Timeline Impacts:"
        pdf.font "Helvetica", size: 10
        stats[:timeline_impacts].each do |impact, count|
          pdf.text "• #{impact}: #{count} reports" if impact.present?
        end
        pdf.move_down 20
      end

      # Individual Reports Section
      pdf.start_new_page
      pdf.font "Helvetica", size: 16, style: :bold
      pdf.text "Anonymized Reports"
      pdf.move_down 15

      reports.each_with_index do |report, index|
        # Start new page for each report after the first
        pdf.start_new_page if index > 0

        pdf.font "Helvetica", size: 12, style: :bold
        pdf.text "Report ##{report.id}: #{report.project_type} in #{report.location}"
        pdf.move_down 5

        pdf.font "Helvetica", size: 9
        pdf.text "Verified: #{report.verified_at&.strftime('%B %d, %Y')}"
        pdf.move_down 10

        pdf.font "Helvetica", size: 11, style: :bold
        pdf.text "Project Description:"
        pdf.font "Helvetica", size: 10
        pdf.text report.project_description
        pdf.move_down 10

        pdf.font "Helvetica", size: 11, style: :bold
        pdf.text "Issue Description:"
        pdf.font "Helvetica", size: 10
        pdf.text report.issue_description
        pdf.move_down 10

        if report.timeline_impact.present?
          pdf.font "Helvetica", size: 10, style: :bold
          pdf.text "Timeline Impact: ", inline: true
          pdf.font "Helvetica", size: 10
          pdf.text report.timeline_impact, inline: true
          pdf.move_down 5
        end

        if report.financial_impact.present?
          pdf.font "Helvetica", size: 10, style: :bold
          pdf.text "Financial Impact: ", inline: true
          pdf.font "Helvetica", size: 10
          pdf.text report.financial_impact, inline: true
          pdf.move_down 5
        end

        if report.departments.any?
          pdf.font "Helvetica", size: 10, style: :bold
          pdf.text "Departments: ", inline: true
          pdf.font "Helvetica", size: 10
          pdf.text report.departments.join(", "), inline: true
          pdf.move_down 5
        end

        if report.issue_categories.any?
          pdf.font "Helvetica", size: 10, style: :bold
          pdf.text "Issue Categories: ", inline: true
          pdf.font "Helvetica", size: 10
          pdf.text report.issue_categories.join(", "), inline: true
          pdf.move_down 5
        end

        if report.solution_ideas.present?
          pdf.move_down 5
          pdf.font "Helvetica", size: 11, style: :bold
          pdf.text "Solution Ideas from Submitter:"
          pdf.font "Helvetica", size: 10
          pdf.text report.solution_ideas
        end
      end
    end
  end
end
