class ReportMailer < ApplicationMailer
  def verification(report)
    @report = report
    @verification_url = verify_report_url(token: report.verification_token, host: "redtape.la", protocol: "https")

    mail(
      to: report.email,
      subject: "Verify your Red Tape Report"
    )
  end
end
