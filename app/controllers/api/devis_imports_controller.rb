class Api::DevisImportsController < ApplicationController
  skip_before_action :verify_authenticity_token

  MAX_FILE_SIZE = 20.megabytes

  def create
    supplier_name = params[:supplier].to_s.strip
    file = params[:file]

    return render json: { error: "Fournisseur manquant." }, status: :unprocessable_entity if supplier_name.blank?
    return render json: { error: "Aucun fichier reçu." }, status: :unprocessable_entity if file.blank?
    return render json: { error: "Le fichier dépasse 20 Mo." }, status: :unprocessable_entity if file.size > MAX_FILE_SIZE

    supplier = Supplier.find_by(name: supplier_name)
    return render json: { error: "Fournisseur inconnu : #{supplier_name}" }, status: :unprocessable_entity unless supplier

    lines = DevisExtractorService.new(file.read, supplier_name).extract
    render json: { items: lines.map { |line| build_cart_line(supplier, line) } }
  rescue DevisExtractorService::ExtractionError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def build_cart_line(supplier, line)
    reference = line[:reference].to_s.strip
    quantity  = line[:quantity].to_f
    devis_price = line[:unit_price].presence && line[:unit_price].to_f
    product = reference.present? ? Product.where(supplier: supplier).where("upper(reference) = ?", reference.upcase).first : nil

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
      }
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
        cheaperAtSupplier: false
      }
    end
  end
end
