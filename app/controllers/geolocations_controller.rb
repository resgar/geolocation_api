class GeolocationsController < ApplicationController
  before_action :set_geolocation, only: %i[show destroy]

  # GET /geolocations/1
  def show; end

  # POST /geolocations
  def create
    service = GeolocationService.new(**geolocation_params)
    result = service.fetch_and_save

    if result[:success]
      @geolocation = result[:geolocation]
      render :show, status: :created
    else
      render_unprocessable_entity(result[:error])
    end
  end

  # DELETE /geolocations/1
  def destroy
    @geolocation.destroy!
  end

  private

  def set_geolocation
    url = params[:url]
    resolved_ip = resolve_ip_address(url) if url.present?
    ip_address = resolved_ip || params[:ip_address]

    if ip_address.blank?
      return render_unprocessable_entity("IP address parameter is required")
    end

    unless validate_ip_address(ip_address)
      return render_bad_request("Invalid IP address format")
    end

    @geolocation = Geolocation.find_by(ip_address:)
    unless @geolocation
      message = "Geolocation data not found for IP address #{params[:ip_address]}"
      render_not_found(message)
    end
  end

  # Only allow a list of trusted parameters through.
  def geolocation_params
    params.require(:geolocation).permit(:ip_address, :url).to_h.symbolize_keys
  end

  def render_not_found(detail)
    render json: {
      errors: [
        {
          status: "404",
          title: "Not Found",
          detail:
        }
      ]
    }, status: :not_found
  end

  def render_bad_request(detail)
    render json: { errors: [ { status: "400", title: "Bad Request", detail: } ] }, status: :bad_request
  end

  def render_unprocessable_entity(detail)
    render json: { errors: [ { status: "422", title: "Unprocessable Entity", detail: } ] }, status: :unprocessable_entity
  end

  def validate_ip_address(ip_address)
    IPAddr.new(ip_address)
  rescue IPAddr::InvalidAddressError
    nil
  end

  def resolve_ip_address(url)
    Resolv.getaddress(url)
  rescue Resolv::ResolvError
    render_bad_request("Invalid URL format")
  end
end
