class ApplicationController < ActionController::API
  include ApiAuthentication

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from Geolocation::Errors::InvalidQueryError, with: :render_unprocessable
  rescue_from Geolocation::Errors::RateLimitedError, with: :render_rate_limited
  rescue_from Geolocation::Errors::NotConfiguredError, with: :render_provider_misconfigured
  rescue_from Geolocation::Errors::ProviderUnavailableError, with: :render_provider_unavailable
  rescue_from Geolocation::Errors::ProviderError, with: :render_provider_error

  private

  def render_error(status:, title:, detail: nil)
    render json: { errors: [ { status: Rack::Utils.status_code(status).to_s, title: title, detail: detail || title } ] },
           status: status
  end

  def render_not_found(exception)
    render_error(status: :not_found, title: "Not Found", detail: exception.message)
  end

  def render_unprocessable(exception)
    render_error(status: :unprocessable_content, title: "Unprocessable Entity", detail: exception.message)
  end

  def render_bad_request(exception)
    render_error(status: :bad_request, title: "Bad Request", detail: exception.message)
  end

  def render_rate_limited(exception)
    render_error(status: :too_many_requests, title: "Provider Rate Limited", detail: exception.message)
  end

  def render_provider_misconfigured(exception)
    render_error(status: :service_unavailable, title: "Geolocation Provider Misconfigured", detail: exception.message)
  end

  def render_provider_unavailable(exception)
    render_error(status: :bad_gateway, title: "Geolocation Provider Unavailable", detail: exception.message)
  end

  def render_provider_error(exception)
    render_error(status: :bad_gateway, title: "Geolocation Provider Error", detail: exception.message)
  end
end
