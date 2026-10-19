# Agent de commande vocale — environnement test « Développement » uniquement
# (voir VoiceAgentService). Le navigateur garde l'historique et renvoie le tout.
class Api::VoiceAgentController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :require_dev_mode

  def create
    messages = Array(params[:messages]).last(20).filter_map { |m|
      role = m[:role].to_s
      text = m[:content].to_s.strip.first(1000)
      { "role" => role, "content" => text } if %w[user assistant].include?(role) && text.present?
    }
    return render json: { error: "Message vide." }, status: :unprocessable_entity unless messages.last && messages.last["role"] == "user"

    result = VoiceAgentService.new(user: current_user, messages: messages, cart_supplier: params[:cart_supplier]).call
    render json: result
  rescue VoiceAgentService::AgentError => e
    render json: { error: e.message }, status: :bad_gateway
  end

  private

  def require_dev_mode
    return if Api::TestProfilesController.dev_mode?(session, current_user)
    render json: { error: "Réservé à l'environnement test." }, status: :forbidden
  end
end
