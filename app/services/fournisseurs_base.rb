# Base fournisseurs Induni (≈ 9 300 fiches, issue de l'export comptable) : la
# même liste que celle du menu « Nom du fournisseur » du bon de commande
# générique (JSON embarqué dans app/views/generic_orders/form.html), exposée ici
# pour que l'import de devis propose exactement la même base.
module FournisseursBase
  FORM_PATH = Rails.root.join("app/views/generic_orders/form.html")
  JSON_TAG  = %r{<script type="application/json" id="fournisseurs-data">(.*?)</script>}m

  module_function

  def all
    @all ||= begin
      json = File.read(FORM_PATH)[JSON_TAG, 1]
      json ? JSON.parse(json) : []
    end
  end

  # Noms uniques, triés sans accents ni casse.
  def names
    @names ||= all.filter_map { |f| f["nom"].to_s.strip.presence }.uniq.sort_by { |n| I18n.transliterate(n).downcase }
  end

  def find(name)
    wanted = name.to_s.strip.downcase
    return nil if wanted.empty?

    all.find { |f| f["nom"].to_s.strip.downcase == wanted }
  end

  # Fiche Supplier correspondant à ce nom : celle de la base e-shop si elle
  # existe, sinon créée à partir de la fiche de la base fournisseurs.
  def find_or_create_supplier(name)
    name = name.to_s.strip
    supplier = Supplier.where("lower(name) = ?", name.downcase).first
    return supplier if supplier

    entry = find(name) or return nil
    Supplier.create!(
      name: entry["nom"].to_s.strip, email: entry["email"].presence, phone: entry["tel"].presence,
      address: entry["adresse"].presence, postal_code: entry["npa"].presence, city: entry["lieu"].presence,
      country_code: entry["pays"].presence, supplier_number: entry["numFournisseur"].presence
    )
  end
end
