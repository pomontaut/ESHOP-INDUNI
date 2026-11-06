# Module « Import soumission » — ENVIRONNEMENT TEST « Développement » uniquement.
# Un PDF de soumission (positions surlignées) est lu puis chiffré avec les catalogues de l'e-shop ;
# les rapprochements validés/refusés alimentent la mémoire (SoumissionMatch). Prix confidentiels jamais exposés.
class Api::SoumissionImportsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :require_dev_mode

  MAX_FILE_SIZE = 30.megabytes

  def create
    file = params[:file]
    return render json: { error: "Aucun fichier reçu." }, status: :unprocessable_entity if file.blank?
    return render json: { error: "Le fichier dépasse 30 Mo." }, status: :unprocessable_entity if file.size > MAX_FILE_SIZE

    service = extractor.new(file.read)
    items = service.extract
    render json: { items: price_items(items), truncated: service.truncated ? true : false }
  rescue SoumissionExtractorService::ExtractionError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # Re-chiffre des lignes déjà extraites (après correction d'une désignation, par exemple).
  def price
    lines = Array(params[:lines]).map { |l| l.permit(:pos, :designation, :quantity, :unit, :cfc, :chapter, :highlight).to_h.symbolize_keys }
    render json: { items: price_items(lines) }
  end

  # L'utilisateur valide (confirmed) ou refuse (rejected) un article proposé : la mémoire s'en souvient.
  def learn
    status = params[:status].to_s
    return render json: { error: "Statut inconnu." }, status: :unprocessable_entity unless SoumissionMatch::STATUSES.include?(status)

    product = Product.joins(:supplier).find_by(suppliers: { name: params[:supplier].to_s }, reference: params[:reference].to_s)
    return render json: { error: "Article introuvable." }, status: :not_found unless product
    return render json: { error: "Désignation manquante." }, status: :unprocessable_entity if params[:designation].blank?

    SoumissionMatch.learn!(designation: params[:designation], product: product, status: status, user: current_user)
    render json: { ok: true }
  end

  private

  def extractor = SoumissionExtractorService

  def price_items(items)
    pricer = SoumissionPricer.new
    items.map { |i| i.to_h.symbolize_keys.merge(pricer.price(i.to_h.symbolize_keys)) }
  end

  def require_dev_mode
    return if Api::TestProfilesController.dev_mode?(session, current_user)

    render json: { error: "Module disponible uniquement dans l'environnement test (Développement)." }, status: :forbidden
  end
end
