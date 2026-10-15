require "test_helper"

class StagingMailInterceptorTest < ActiveSupport::TestCase
  def build
    Mail.new(to: "fournisseur@exemple.ch", cc: "copie@induni.ch", subject: "Commande 1", body: "x")
  end

  test "redirects every recipient to STAGING_MAIL_TO and tags the subject" do
    ENV["STAGING_MAIL_TO"] = "dev@induni.ch"
    mail = build
    StagingMailInterceptor.delivering_email(mail)
    assert_equal [ "dev@induni.ch" ], mail.to
    assert_nil mail.cc
    assert_equal "[STAGING] Commande 1", mail.subject
    assert_includes mail.header["X-Original-Recipients"].to_s, "fournisseur@exemple.ch"
  ensure
    ENV.delete("STAGING_MAIL_TO")
  end

  test "sends nothing when STAGING_MAIL_TO is not set" do
    ENV.delete("STAGING_MAIL_TO")
    mail = build
    StagingMailInterceptor.delivering_email(mail)
    assert_equal false, mail.perform_deliveries
  end

  test "automatic relance is always off in staging" do
    ENV["RELANCE_AUTO_ENABLED"] = "true"
    ENV["APP_ENV"] = "staging"
    assert_not OrderRelance.enabled?
    ENV["APP_ENV"] = "production"
    assert OrderRelance.enabled?
  ensure
    ENV.delete("RELANCE_AUTO_ENABLED"); ENV.delete("APP_ENV")
  end
end
