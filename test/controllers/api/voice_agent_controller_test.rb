require "test_helper"

class Api::VoiceAgentControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    post api_voice_agent_url, params: { messages: [ { role: "user", content: "x" } ] }, as: :json
    assert_response :unauthorized
  end

  test "is forbidden outside the Développement test environment, even for an admin" do
    user = users(:two)
    user.update!(admin: true)
    post login_url, params: { email: user.email, password: "password123" }
    post api_voice_agent_url, params: { messages: [ { role: "user", content: "x" } ] }, as: :json
    assert_response :forbidden
  end

  test "in dev mode, rejects an empty conversation" do
    user = users(:two)
    user.update!(admin: true)
    post login_url, params: { email: user.email, password: "password123" }
    post api_test_profile_url, params: { profile: "Développement" }
    post api_voice_agent_url, params: { messages: [] }, as: :json
    assert_response :unprocessable_entity
  end
end
