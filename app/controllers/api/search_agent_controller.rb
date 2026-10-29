# Chat de l'agent « moteur de recherche » : administrateurs seulement (voir SearchAgent).
class Api::SearchAgentController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :require_admin

  def history
    msgs = SearchAgentMessage.order(:id).last(60).map { |m| { role: m.role, content: m.content, at: m.created_at.in_time_zone(UsageReport::ZONE).strftime("%d.%m %H:%M") } }
    render json: { messages: msgs, memory: SearchMemory.active.count, brain: SearchAgent::Brain.available?, rules: SearchMemory.rules_json.size, pending: SearchMemory.where(status: "suggested").count }
  end

  def chat
    text = params[:message].to_s.strip[0, 2000]
    return render(json: { error: "Message vide." }, status: :unprocessable_entity) if text.blank?

    SearchAgentMessage.create!(user_id: current_user.id, role: "user", content: text)
    engine = Array(params[:engine]).map { |e| e.respond_to?(:to_unsafe_h) ? e.to_unsafe_h : e }.first(4)
    res = SearchAgent.new(current_user).reply(text, engine: engine)
    SearchAgentMessage.create!(user_id: current_user.id, role: "agent", content: res.reply)
    render json: { reply: res.reply, changed: res.changed, updates: res.updates, synonyms: res.synonyms ? SearchMemory.synonyms_json : nil, rules: res.synonyms ? SearchMemory.rules_json : nil }
  end

  private

  def require_admin
    render json: { error: "Accès réservé aux administrateurs." }, status: :forbidden unless current_user&.admin?
  end
end
