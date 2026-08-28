# Requires a Bearer token matching ENV["API_TOKEN"] (see .env.example).
# Fails closed: if no API_TOKEN is configured, every request is rejected
# rather than silently left open.
module ApiAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_bearer_token!
  end

  private

  def authenticate_bearer_token!
    return if authenticated?

    render json: { errors: [ { status: "401", title: "Unauthorized", detail: "Missing or invalid bearer token" } ] },
           status: :unauthorized
  end

  def authenticated?
    configured_api_token.present? &&
      ActiveSupport::SecurityUtils.secure_compare(bearer_token.to_s, configured_api_token)
  end

  def bearer_token
    request.headers["Authorization"].to_s[/\ABearer\s+(.+)\z/i, 1]
  end

  def configured_api_token
    ENV["API_TOKEN"]
  end
end
