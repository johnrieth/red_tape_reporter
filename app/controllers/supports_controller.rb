class SupportsController < ApplicationController
  allow_unauthenticated_access

  def create
    @issue = Issue.find(params[:issue_id])

    existing = @issue.supports.find_by(user_id: current_user&.id) if current_user
    if existing
      redirect_to @issue, alert: "You already supported this issue"
      return
    end

    @support = @issue.supports.build(support_params)
    @support.user = current_user if current_user
    @support.anonymity_token = SecureRandom.hex(16) unless current_user

    if @support.save
      redirect_to @issue, notice: "Thanks for your support!"
    else
      redirect_to @issue, alert: "Error saving support"
    end
  end

  private

  def support_params
    params.require(:support).permit(:visibility, :estimated_cost, :project_reference)
  end
end
