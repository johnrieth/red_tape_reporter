class ReportMailer < ApplicationMailer
  def verification(report)
    @report = report
    @verification_url = verify_report_url(token: report.verification_token)

    mail(
      to: report.email,
      subject: "Verify your Red Tape Report"
    )
  end

  def approval_notification(report)
    @report = report

    mail(
      to: report.email,
      subject: "Your Red Tape LA story is now published"
    )
  end
end
