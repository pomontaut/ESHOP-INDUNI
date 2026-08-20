class ApplicationController < ActionController::Base
  before_action :require_login

  private

  def require_login
    return if current_user

    # Les routes /api/* sont appelées en fetch() par catalogue.html, qui
    # n'envoie pas forcément un en-tête Accept: application/json — se fier
    # au chemin plutôt qu'au format négocié évite de rediriger un appel API
    # vers la page de login HTML (que le fetch() interpréterait à tort comme
    # une réponse JSON invalide plutôt qu'un vrai refus d'accès).
    if request.path.start_with?("/api/")
      render json: { error: "Authentification requise" }, status: :unauthorized
    else
      redirect_to login_path, alert: "Veuillez vous connecter pour accéder à cette page."
    end
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
  helper_method :current_user

  def render_order_pdf(order)
    @order = order
    html = render_to_string(template: "orders/bon_de_commande", layout: false, formats: [ :html ])
    WickedPdf.new.pdf_from_string(html)
  end
end
