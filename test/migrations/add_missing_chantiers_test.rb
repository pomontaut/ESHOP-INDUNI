require "test_helper"
require Rails.root.join("db/migrate/20261016120000_add_missing_chantiers_from_export_20261014")

class AddMissingChantiersTest < ActiveSupport::TestCase
  setup do
    @data = JSON.parse(File.read(AddMissingChantiersFromExport20261014::DATA_PATH))
    Chantier.delete_all
  end

  def run_migration
    ActiveRecord::Migration.suppress_messages { AddMissingChantiersFromExport20261014.new.up }
  end

  test "creates every missing chantier once and is idempotent (no duplicates)" do
    run_migration
    assert_equal @data.size, Chantier.count
    run_migration
    assert_equal @data.size, Chantier.count
    assert_equal @data.size, Chantier.distinct.count(:nom)
    assert_equal @data.count { |c| c["consortium"] }, Chantier.where(consortium: true).count
  end

  test "never duplicates a chantier already present under the same number, only aligns its consortium status" do
    sample = @data.find { |c| c["consortium"] }
    number = sample["nom"][/\A(\d+)-/, 1]
    existing = Chantier.create!(nom: "#{number}-Ancien libellé", consortium: false)

    run_migration

    assert_equal 1, Chantier.where("nom LIKE ?", "#{number}-%").count
    assert existing.reload.consortium?
  end

  test "created chantiers carry no _INACTIF marker and no placeholder values" do
    run_migration
    assert_equal 0, Chantier.where("technicien LIKE '%INACTIF%' OR contremaitre LIKE '%INACTIF%' OR chef_equipe LIKE '%INACTIF%'").count
    assert_equal 0, Chantier.where(technicien: "NULL").count
  end
end
