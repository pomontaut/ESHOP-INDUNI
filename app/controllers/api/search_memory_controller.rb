# Mémoire du moteur de recherche (synonymes appris par l'agent « moteur de recherche »), lue par tous
# les utilisateurs connectés : le navigateur l'injecte dans la table de synonymes du bandeau de recherche.
class Api::SearchMemoryController < ApplicationController
  def index
    render json: { synonyms: SearchMemory.synonyms_json }
  end
end
