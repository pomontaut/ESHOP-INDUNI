class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("SMTP_FROM", ENV.fetch("SMTP_USERNAME", "noreply@induni.ch"))
  layout "mailer"
end
