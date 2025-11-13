# Preview all emails at http://localhost:3000/rails/mailers/admin_notification_mailer
class AdminNotificationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/admin_notification_mailer/new_verified_report
  def new_verified_report
    AdminNotificationMailer.new_verified_report
  end
end
