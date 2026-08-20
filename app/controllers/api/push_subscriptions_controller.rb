class Api::PushSubscriptionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    endpoint = params[:endpoint].to_s
    keys = params[:keys] || {}
    return render json: { error: "endpoint et clés requis" }, status: :unprocessable_entity if endpoint.blank? || keys[:p256dh].blank? || keys[:auth].blank?

    subscription = current_user.push_subscriptions.find_or_initialize_by(endpoint: endpoint)
    subscription.update!(p256dh_key: keys[:p256dh], auth_key: keys[:auth])
    head :no_content
  end

  def destroy
    current_user.push_subscriptions.where(endpoint: params[:endpoint].to_s).destroy_all
    head :no_content
  end
end
