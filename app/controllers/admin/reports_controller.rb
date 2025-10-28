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

  def show
    @report = Report.not_deleted.find(params[:id])
  end

  def approve
    @report = Report.not_deleted.find(params[:id])
    if @report.approve
      redirect_to admin_reports_path(filter: "pending_review"), notice: "Report approved successfully."
    else
      redirect_to admin_report_path(@report), alert: "Failed to approve report."
    end
  end

  def destroy
    @report = Report.not_deleted.find(params[:id])
    if @report.soft_delete
      redirect_to admin_reports_path(filter: "pending_review"), notice: "Report deleted successfully."
    else
      redirect_to admin_report_path(@report), alert: "Failed to delete report."
    end
  end
end
