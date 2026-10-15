require "test_helper"

class ConducteurTravauxTest < ActiveSupport::TestCase
  test "rejects Pierre-Olivier Montaut in any spelling" do
    [ "Pierre-Olivier Montaut", "MONTAUT Pierre Olivier", "Pierre Olivier MONTAUT", "montaut pierre-olivier", "P-O Montaut", "PO Montaut" ].each do |name|
      assert ConducteurTravaux.forbidden?(name), name
      assert_nil ConducteurTravaux.sanitize(name)
    end
  end

  test "keeps other names, including other Montaut or other Pierre" do
    assert_equal "Paul Dupont", ConducteurTravaux.sanitize("  Paul Dupont ")
    assert_equal "Pierre Martin", ConducteurTravaux.sanitize("Pierre Martin")
    assert_equal "Marc Montaut", ConducteurTravaux.sanitize("Marc Montaut")
    assert_nil ConducteurTravaux.sanitize("")
  end
end
