class IssuesController < ApplicationController
  allow_unauthenticated_access

  def index
    @issues = Issue.public_visible.includes(:supports)

    case params[:sort]
    when "impact"
      @issues = @issues.sort_by { |i| -i.cost_impact_total }
    when "trending"
      @issues = @issues.by_trending
    else
      @issues = @issues.by_support_count
    end

    @issues = @issues.where(category: params[:category]) if params[:category].present?

    @page_title = "Bureaucratic Obstacles in LA County"
  end

  def show
    @issue = Issue.find(params[:id])
    @supports = @issue.supports.includes(:user, :support_comments).order(created_at: :desc)
    @new_support = Support.new
  end
end
