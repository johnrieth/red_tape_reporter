class Admin::ReportsController < Admin::BaseController
  def index
    @reports = Report.order(created_at: :desc)
    @total_reports = @reports.count
    @new_reports = @reports.where(status: "new").count
  end

  def show
    @report = Report.find(params[:id])
  end
end
