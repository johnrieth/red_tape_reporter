class StoriesController < ApplicationController
  allow_unauthenticated_access

  def index
    @stories = Report.publicly_shared.recent

    # Filter by location
    if params[:location].present?
      location_query = "%#{params[:location]}%"
      @stories = @stories.where("location LIKE ?", location_query)
    end

    # Filter by issue category
    if params[:category].present?
      @stories = @stories.select { |s| s.issue_categories.include?(params[:category]) }
    end

    # Filter by timeline impact
    if params[:timeline].present?
      @stories = @stories.where(timeline_impact: params[:timeline])
    end

    # Filter by financial impact
    if params[:financial_impact].present?
      @stories = @stories.where(financial_impact: params[:financial_impact])
    end

    # Filter by department
    if params[:department].present?
      @stories = @stories.select { |s| s.departments.include?(params[:department]) }
    end

    # Convert back to ActiveRecord::Relation if we used select
    if @stories.is_a?(Array)
      @stories = Report.where(id: @stories.map(&:id)).order(created_at: :desc)
    end

    # Calculate aggregate statistics
    calculate_aggregates
  end

  def show
    @story = Report.publicly_shared.find(params[:id])
    @related_stories = @story.related_reports(limit: 5)
    @comments = @story.comments.oldest_first
    @voter_token = get_or_create_voter_token
    @has_voted = @story.voted_by?(@voter_token)
  rescue ActiveRecord::RecordNotFound
    redirect_to stories_path, alert: "Story not found or not publicly available."
  end

  private

  def calculate_aggregates
    stories_for_stats = @stories.respond_to?(:to_a) ? @stories.to_a : @stories.load

    @total_stories = stories_for_stats.size

    # Department breakdown
    department_counts = Hash.new(0)
    stories_for_stats.each do |story|
      story.departments.each { |dept| department_counts[dept] += 1 }
    end
    @department_breakdown = department_counts.sort_by { |_k, v| -v }.first(10)

    # Issue category breakdown
    category_counts = Hash.new(0)
    stories_for_stats.each do |story|
      story.issue_categories.each { |cat| category_counts[cat] += 1 }
    end
    @category_breakdown = category_counts.sort_by { |_k, v| -v }.first(10)

    # Timeline impact breakdown
    @timeline_breakdown = stories_for_stats.group_by(&:timeline_impact)
      .transform_values(&:count)
      .sort_by { |k, _v| Report::TIMELINE_IMPACTS.index(k) || 999 }

    # Location breakdown (top cities)
    @location_breakdown = stories_for_stats.group_by(&:location)
      .transform_values(&:count)
      .sort_by { |_k, v| -v }
      .first(10)

    # Financial impact stats
    @stories_with_financial_impact = stories_for_stats.count { |s| s.financial_impact.present? }

    # Total vote count across all stories
    @total_votes = stories_for_stats.sum(&:vote_count)
  end

  def get_or_create_voter_token
    cookies.permanent.signed[:voter_token] ||= SecureRandom.urlsafe_base64(32)
  end
end
