class SupportCommentsController < ApplicationController
  allow_unauthenticated_access

  def create
    @support = Support.find(params[:support_id])

    @comment = @support.support_comments.build(comment_params)
    @comment.user = current_user if current_user

    if @comment.save
      redirect_to @support.issue, notice: "Comment added"
    else
      redirect_to @support.issue, alert: "Error saving comment"
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:content, :visibility)
  end
end
