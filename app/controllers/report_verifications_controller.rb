class ReportVerificationsController < ApplicationController
  allow_unauthenticated_access

  def verify
    @report = Report.find_by(verification_token: params[:token])

    if @report.nil?
      redirect_to root_path, alert: "Invalid verification link."
    elsif @report.verified_at.present?
      redirect_to root_path, notice: "This report has already been verified. Thank you!"
    else
      @report.update!(verified_at: Time.current, status: "verified")
      # Success - show the verify view
    end
  end
end
