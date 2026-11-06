require "test_helper"

class SoumissionExtractorServiceTest < ActiveSupport::TestCase
  def parse(raw) = SoumissionExtractorService.new("x").send(:parse, raw)
  ITEM = '{"pos":"1","designation":"Tuyau","quantity":1,"unit":"ml","cfc":"","chapter":"","highlight":"jaune"}'

  test "JSON valide, avec ou sans balises" do
    assert_equal 1, parse(%({"items":[#{ITEM}]})).size
    assert_equal 1, parse("```json\n{\"items\":[#{ITEM}]}\n```").size
  end

  test "réponse coupée : garde les positions complètes" do
    svc = SoumissionExtractorService.new("x")
    items = svc.send(:parse, %({"items":[#{ITEM},#{ITEM},{"pos":"3","designa))
    assert_equal 2, items.size
    assert svc.truncated
  end

  test "réponse inutilisable : erreur claire" do
    assert_raises(SoumissionExtractorService::ExtractionError) { parse("n'importe quoi") }
  end
end
