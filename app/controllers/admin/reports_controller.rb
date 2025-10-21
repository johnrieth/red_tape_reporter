class Admin::ReportsController < Admin::BaseController
  def index
    # Filter by status
    @filter = params[:filter] || "all"
    @reports = case @filter
    when "pending_review"
                 Report.pending_review.recent
    when "approved"
                 Report.approved.recent
    when "unverified"
                 Report.unverified.recent
    else
                 Report.not_deleted.recent
    end

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
