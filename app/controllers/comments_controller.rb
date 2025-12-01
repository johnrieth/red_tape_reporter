class CommentsController < ApplicationController
  allow_unauthenticated_access

  def create
    @story = Report.publicly_shared.find(params[:story_id])
    commenter_token = get_or_create_commenter_token

    @comment = @story.comments.build(comment_params.merge(commenter_token: commenter_token))

    if @comment.save
      respond_to do |format|
        format.html { redirect_to story_path(@story), notice: "Comment added!" }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to story_path(@story), alert: @comment.errors.full_messages.join(", ") }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("comment_form", partial: "comments/form", locals: { story: @story, comment: @comment }) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to stories_path, alert: "Story not found."
  end

  private

  def comment_params
    params.require(:comment).permit(:content)
  end

  def get_or_create_commenter_token
    cookies.permanent.signed[:commenter_token] ||= SecureRandom.urlsafe_base64(32)
  end
end
