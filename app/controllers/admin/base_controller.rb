class Admin::BaseController < ApplicationController
  before_action :require_admin

  private

  def require_admin
    unless Current.user&.admin?
      redirect_to root_path, alert: "Access denied"
    end
  end
end
