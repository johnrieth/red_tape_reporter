class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    @reset_url = edit_password_url(user.password_reset_token, host: "redtape.la", protocol: "https")
    mail subject: "Reset your password", to: user.email_address
  end
end
