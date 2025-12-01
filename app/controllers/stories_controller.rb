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
    build_top_issues
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

  # Browse action: supports simple sorting and the same filters as index
  def browse
    @stories = Report.publicly_shared.recent

    # Reuse index filters where present
    %i[location category timeline financial_impact department].each do |p|
      if params[p].present?
        case p
        when :location
          q = "%#{params[:location]}%"
          @stories = @stories.where("location LIKE ?", q)
        when :category
          @stories = @stories.select { |s| s.issue_categories.include?(params[:category]) }
        when :timeline
          @stories = @stories.where(timeline_impact: params[:timeline])
        when :financial_impact
          @stories = @stories.where(financial_impact: params[:financial_impact])
        when :department
          @stories = @stories.select { |s| s.departments.include?(params[:department]) }
        end
      end
    end

    # Convert to ActiveRecord relation if needed
    @stories = Report.where(id: @stories.map(&:id)).order(created_at: :desc) if @stories.is_a?(Array)

    # Sorting
    case params[:sort]
    when "highest_impact"
      # crude heuristic: prefer stories with financial_impact present
      @stories = @stories.sort_by { |s| s.financial_impact.present? ? 0 : 1 }
    when "most_reports"
      @stories = @stories.sort_by { |s| -s.comments.count }
    when "rising_trend"
      # no trend engine yet; fallback to most recent
      @stories = @stories.order(created_at: :desc)
    else
      @stories = @stories.order(created_at: :desc)
    end
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

  # Build a small list of the top 3 issues (category-centric) with simple estimates
  # Uses reported stories to compute counts and a most-common financial impact string.
  def build_top_issues
    # group stories by issue category and count
    counts = Hash.new { |h, k| h[k] = { count: 0, stories: [] } }
    @stories.each do |s|
      s.issue_categories.each do |cat|
        counts[cat][:count] += 1
        counts[cat][:stories] << s
      end
    end

    top = counts.sort_by { |_k, v| -v[:count] }.first(3)

    @top_issues = top.map do |category, data|
      stories = data[:stories]
      # Most common financial impact string among these stories
      cost = stories.map(&:financial_impact).compact.group_by { |c| c }.max_by { |_k, v| v.size }&.first

      # Estimate scale: number of distinct projects reported (use count)
      scale = data[:count]

      {
        category: category,
        count: data[:count],
        sample_cost: cost,
        stories: stories.first(3),
        scale: scale
      }
    end
  end

  def get_or_create_voter_token
    cookies.permanent.signed[:voter_token] ||= SecureRandom.urlsafe_base64(32)
  end
end
