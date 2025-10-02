class ApplicationMailer < ActionMailer::Base
  default from: "Red Tape Reporter <reports@verify.redtape.la>"
  layout "mailer"
end
