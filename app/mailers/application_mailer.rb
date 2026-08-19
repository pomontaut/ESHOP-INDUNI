class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("SMTP_FROM", ENV.fetch("SMTP_USERNAME", "commande_induni_eshop@indunieshop.ch"))
  layout "mailer"
end
