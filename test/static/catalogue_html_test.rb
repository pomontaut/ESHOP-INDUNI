require "test_helper"

# Garde-fous sur le gabarit de bon de commande généré côté navigateur
# (aperçu / PDF de repli) : il ne doit pas réintroduire « Commandé par » en bas.
class CatalogueHtmlTest < ActiveSupport::TestCase
  test "the client-side order preview has no « Commandé par » line" do
    html = File.read(Rails.root.join("public/catalogue.html"))
    assert_not_includes html, "Commandé par"
  end

  test "the emailed order PDF template has no « Commandé par » line either" do
    assert_not_includes File.read(Rails.root.join("app/views/orders/bon_de_commande.html.erb")), "Commandé par"
  end
end
