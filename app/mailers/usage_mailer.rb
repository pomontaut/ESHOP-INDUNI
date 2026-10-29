class UsageMailer < ApplicationMailer
  helper UsageHelper

  def daily_report(to, report)
    @report = report
    mail(to: to, subject: "E-shop Induni — compte rendu d'usage du #{Date.parse(report[:date]).strftime('%d.%m.%Y')}")
  end
end
