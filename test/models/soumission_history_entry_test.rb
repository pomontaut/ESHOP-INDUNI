require "test_helper"

class SoumissionHistoryEntryTest < ActiveSupport::TestCase
  setup do
    SoumissionHistoryEntry.delete_all
    SoumissionHistoryEntry.create!(designation: "Fourniture et pose de regard DN 600 profondeur 1.50 m", norm_text: "x1", unit: "p", scope: "article",
      tokens: SoumissionHistoryEntry.tokenize("Fourniture et pose de regard DN 600 profondeur 1.50 m").join(" "), occurrences: 4, year_from: 2012, year_to: 2024)
    SoumissionHistoryEntry.create!(designation: "DN/OD 200.", norm_text: "x2", unit: "m", scope: "article",
      tokens: SoumissionHistoryEntry.tokenize("DN/OD 200.").join(" "), occurrences: 76)
    SoumissionHistoryEntry.reset_index!
  end
  teardown { SoumissionHistoryEntry.reset_index! }

  test "retrouve une position proche et ignore les correspondances par chiffres seuls" do
    hits = SoumissionHistoryEntry.similar("Regard de visite DN 600 profondeur 1.50 m", unit: "p")
    assert_equal [ "x1" ], hits.map { |e, _| SoumissionHistoryEntry.find(e[:id]).norm_text }
    assert_empty SoumissionHistoryEntry.similar("Tuyau PVC DN 200")
  end

  test "le seed charge le fichier historique" do
    assert SoumissionHistoryEntry.seed_from_json! > 20_000
    assert SoumissionHistoryEntry.where(scope: "titre").exists?
  end
end
