class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]

  def new
  end

  def create
    # Prevent timing attacks by always taking similar time
    # whether the user exists or not
    user = User.find_by(email_address: params[:email_address])

    if user
      PasswordsMailer.reset(user).deliver_later
    else
      # Perform a dummy bcrypt operation to match timing of password operations
      # This prevents timing attacks to enumerate valid email addresses
      BCrypt::Password.create("dummy_password_to_prevent_timing_attack")
    end

    redirect_to new_session_path, notice: "Password reset instructions sent (if user with that email address exists)."
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      redirect_to new_session_path, notice: "Password has been reset."
    else
      redirect_to edit_password_path(params[:token]), alert: "Passwords did not match."
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "Password reset link is invalid or has expired."
    end
end
