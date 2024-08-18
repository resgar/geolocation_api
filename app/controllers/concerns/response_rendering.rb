module ResponseRendering
  extend ActiveSupport::Concern

  included do
    def render_error(status, detail)
      render json: {
        errors: [
          {
            status:  Rack::Utils::SYMBOL_TO_STATUS_CODE[status].to_s,
            title: status.to_s.split("_").map(&:capitalize).join(" "),
            detail: detail
          }
        ]
      }, status: status
    end

    [ :not_found, :bad_request, :unprocessable_content ].each do |status|
      define_method("render_#{status}") do |detail|
        render_error(status, detail)
      end
    end
  end
end
