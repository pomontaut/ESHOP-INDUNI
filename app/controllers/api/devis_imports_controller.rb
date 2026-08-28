class Api::DevisImportsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :require_import_quote_permission

  MAX_FILE_SIZE = 20.megabytes

  def create
    supplier_name = params[:supplier].to_s.strip
    file = params[:file]

    return render json: { error: "Fournisseur manquant." }, status: :unprocessable_entity if supplier_name.blank?
    return render json: { error: "Aucun fichier reçu." }, status: :unprocessable_entity if file.blank?
    return render json: { error: "Le fichier dépasse 20 Mo." }, status: :unprocessable_entity if file.size > MAX_FILE_SIZE

    supplier = Supplier.find_by(name: supplier_name)
    return render json: { error: "Fournisseur inconnu : #{supplier_name}" }, status: :unprocessable_entity unless supplier

    taxonomy = Product.where(supplier: supplier).where.not(famille: nil).distinct.pluck(:famille, :sous_famille)
    extracted = DevisExtractorService.new(file.read, supplier_name, taxonomy).extract
    item_lines = extracted[:items].map { |line| build_cart_line(supplier, line) }
    surcharge_lines = extracted[:surcharges].map { |surcharge| build_surcharge_line(supplier, surcharge) }
    render json: { items: item_lines + surcharge_lines }
  rescue DevisExtractorService::ExtractionError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # Called when the user confirms adding unmatched (generic) devis lines to
  # our permanent catalog under the confirmed supplier, instead of only using
  # them as one-off cart lines. Marked manually_added so catalog:seed's
  # full-refresh cleanup for HGC/Leuba HIAG never deletes them (see
  # lib/tasks/catalog_seed.rake) — if the same reference later shows up in a
  # real JSON catalog update, that upsert naturally "graduates" the row into
  # a normal, JSON-sourced entry (manually_added reset to false).
  def confirm_products
    supplier_name = params[:supplier].to_s.strip
    supplier = Supplier.find_by(name: supplier_name)
    return render json: { error: "Fournisseur inconnu : #{supplier_name}" }, status: :unprocessable_entity unless supplier

    products = Array(params[:products]).map do |p|
      reference = p[:reference].to_s.strip
      next if reference.blank?

      product = Product.find_or_initialize_by(supplier: supplier, reference: reference)
      # Never overwrite a real catalog entry (JSON-sourced, not manually
      # added) that happens to share this reference — just skip it.
      next if product.persisted? && !product.manually_added?

      # When the achats/admin user doesn't know which family to file the
      # article under, it's left without famille/sous_famille (hidden from
      # normal catalog browsing, see Api::ProductsController) and flagged
      # needs_classification so it surfaces in the Nomenclature tab instead.
      needs_classification = ActiveModel::Type::Boolean.new.cast(p[:needsClassification]) || false

      product.assign_attributes(
        name:              p[:designation].to_s,
        unit_price:        p[:prix].to_f,
        unite:             p[:unite].to_s.presence || "PCE",
        famille:           needs_classification ? nil : (p[:famille].to_s.presence || "Article générique"),
        sous_famille:      needs_classification ? nil : (p[:sousFamille].to_s.presence || "Devis import"),
        sous_sous_famille: needs_classification ? nil : "__DIRECT__",
        icone:             product.icone.presence || "📦",
        manually_added:    true,
        needs_classification: needs_classification
      )
      product.save!
      product.reference
    end.compact

    render json: { added: products }
  end

  private

  def build_surcharge_line(supplier, surcharge)
    {
      matched: false,
      generic: true,
      isSurcharge: true,
      catalog: supplier.name,
      article: "SURCHARGE-#{SecureRandom.hex(3)}",
      designation: surcharge[:label].to_s,
      descriptif: "Supplément du devis #{supplier.name} (proportionnel au poids/volume de la commande)",
      prix: nil,
      unite: "FRS",
      famille: "Article générique",
      sousFamille: "Devis import",
      icone: "⛽",
      image: nil,
      qty: 1,
      devisPrix: surcharge[:amount].to_f,
      cheaperAtSupplier: false
    }
  end

  def require_import_quote_permission
    unless current_user&.effective_can_import_quote?
      render json: { error: "Vous n'avez pas accès au module d'import de devis." }, status: :forbidden
    end
  end

  def build_cart_line(supplier, line)
    reference = line[:reference].to_s.strip
    quantity  = line[:quantity].to_f
    devis_price = line[:unit_price].presence && line[:unit_price].to_f
    product = reference.present? ? Product.where(supplier: supplier).where("upper(reference) = ?", reference.upcase).first : nil
    equivalent = equivalent_finder.find(line[:designation], exclude: product)

    if product
      {
        matched: true,
        generic: false,
        catalog: supplier.name,
        article: product.reference,
        designation: product.name,
        descriptif: product.descriptif,
        prix: product.unit_price.to_f,
        unite: product.unite,
        famille: product.famille,
        sousFamille: product.sous_famille,
        sousSousFamille: product.sous_sous_famille,
        icone: product.icone,
        image: product.image,
        qty: quantity,
        devisPrix: devis_price,
        cheaperAtSupplier: devis_price.present? && devis_price > 0 && devis_price < product.unit_price.to_f
      }.merge(equivalent_fields(equivalent, devis_price))
    else
      {
        matched: false,
        generic: true,
        catalog: supplier.name,
        article: reference.presence || "GEN-#{SecureRandom.hex(3)}",
        designation: line[:designation].to_s,
        descriptif: "Article générique (devis #{supplier.name})",
        prix: nil,
        unite: line[:unit].to_s.presence || "PCE",
        famille: "Article générique",
        sousFamille: "Devis import",
        icone: "＋",
        image: "construction material",
        qty: quantity,
        devisPrix: devis_price,
        cheaperAtSupplier: false,
        suggestedFamille: line[:suggested_famille],
        suggestedSousFamille: line[:suggested_sous_famille]
      }.merge(equivalent_fields(equivalent, devis_price))
    end
  end

  # Recherche, pour CHAQUE ligne de devis (référencée ou générique), un
  # article équivalent déjà connu ailleurs dans nos catalogues (n'importe
  # quel fournisseur) par similarité de désignation — pour avertir l'acheteur
  # si on a déjà moins cher ailleurs avant qu'il accepte le prix du devis.
  def equivalent_finder
    @equivalent_finder ||= EquivalentProductFinder.new
  end

  def equivalent_fields(equivalent, devis_price)
    return { equivalent: nil, equivalentCheaper: false } unless equivalent

    {
      equivalent: {
        catalog: equivalent.supplier.name,
        article: equivalent.reference,
        designation: equivalent.name,
        prix: equivalent.unit_price.to_f,
        unite: equivalent.unite
      },
      equivalentCheaper: devis_price.present? && devis_price > 0 && equivalent.unit_price.to_f < devis_price
    }
  end
end
