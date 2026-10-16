# Disponibilité HGC d'un article pour un NPA (défaut 1213), lue sur hgc.ch.
# Réservé aux utilisateurs connectés ; l'appel est déclenché à la demande
# depuis la fiche article (voir `hgcStockCheck` dans catalogue.html).
class Api::HgcStockController < ApplicationController
  def show
    info = HgcStock.lookup(params[:article], params[:zip])
    if info
      render json: info
    else
      render json: { error: "Disponibilité indisponible pour le moment." }, status: :bad_gateway
    end
  end
end
