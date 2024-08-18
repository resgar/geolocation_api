class GeolocationsController < ApplicationController
  include ErrorHandler
  include ResponseRendering
  include AddressResolution

  before_action :set_geolocation, only: %i[show destroy]

  # GET /geolocations/1
  def show; end

  # POST /geolocations
  def create
    service = GeolocationService.new(ip_address)
    result = service.fetch_and_save

    if result[:success]
      @geolocation = result[:geolocation]
      render :show, status: :created
    else
      render_unprocessable_content(result[:error])
    end
  end

  # DELETE /geolocations/1
  def destroy
    @geolocation.destroy
  end

  private

  def address
    params[:address]
  end

  def ip_address
    resolve_address(address)
  end

  def set_geolocation
    @geolocation = Geolocation.find_by(ip_address:)
    unless @geolocation
      render_not_found("No record found for #{address}")
    end
  end
end
