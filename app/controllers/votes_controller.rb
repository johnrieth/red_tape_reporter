class VotesController < ApplicationController
  allow_unauthenticated_access

  def create
    @story = Report.publicly_shared.find(params[:story_id])
    voter_token = get_or_create_voter_token

    # Try to create the vote (will fail if already voted due to unique constraint)
    @vote = @story.votes.build(voter_token: voter_token)

    if @vote.save
      respond_to do |format|
        format.html { redirect_to story_path(@story), notice: "Thanks for your support!" }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to story_path(@story), alert: "You've already voted on this story." }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("vote_button_#{@story.id}", partial: "votes/button", locals: { story: @story, has_voted: true }) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to stories_path, alert: "Story not found."
  end

  def destroy
    @story = Report.publicly_shared.find(params[:story_id])
    voter_token = get_or_create_voter_token

    @vote = @story.votes.find_by(voter_token: voter_token)

    if @vote&.destroy
      respond_to do |format|
        format.html { redirect_to story_path(@story), notice: "Vote removed." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to story_path(@story), alert: "You haven't voted on this story." }
        format.turbo_stream
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to stories_path, alert: "Story not found."
  end

  private

  def get_or_create_voter_token
    cookies.permanent.signed[:voter_token] ||= SecureRandom.urlsafe_base64(32)
  end
end
