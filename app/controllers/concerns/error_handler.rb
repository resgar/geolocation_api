module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from(StandardError) do |exception|
      Rails.logger.error("Unexpected error: #{exception.message}")
      render_unprocessable_content(exception.message)
    end

    rescue_from(ArgumentError) do |exception|
      render_bad_request(exception.message)
    end

    rescue_from(URI::InvalidURIError) do |exception|
      render_bad_request("Invalid address format")
    end

    rescue_from(Resolv::ResolvError) do |exception|
      render_unprocessable_content("Unable to resolve the address #{params[:address]}")
    end

    rescue_from(IPAddr::InvalidAddressError) do |exception|
      render_bad_request("Invalid address format")
    end

    rescue_from(ActiveRecord::RecordNotFound) do |exception|
      render json: { errors: "Record not found" }, status: 404
    end

    rescue_from(ActionController::ParameterMissing) do |exception|
      render_bad_request(exception.message)
    end
  end
end
