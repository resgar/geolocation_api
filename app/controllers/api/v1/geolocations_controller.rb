module Api
  module V1
    class GeolocationsController < ApplicationController
      before_action :set_geolocation, only: %i[show destroy]

      # GET /api/v1/geolocations
      # GET /api/v1/geolocations?query=8.8.8.8
      def index
        geolocations = Geolocation.order(created_at: :desc)
        geolocations = geolocations.where(query: filter_query) if params[:query].present?

        render json: GeolocationSerializer.new(geolocations).serializable_hash
      end

      # GET /api/v1/geolocations/:id
      def show
        render json: GeolocationSerializer.new(@geolocation).serializable_hash
      end

      # POST /api/v1/geolocations  { "query": "8.8.8.8" }
      #
      # Looks up (or returns the cached record for) an IP address or URL.
      def create
        outcome = Geolocation::LookupService.call(query_param)

        render json: GeolocationSerializer.new(outcome.record).serializable_hash,
               status: outcome.created? ? :created : :ok
      end

      # DELETE /api/v1/geolocations/:id
      def destroy
        @geolocation.destroy!
        head :no_content
      end

      private

      def set_geolocation
        @geolocation = Geolocation.find(params[:id])
      end

      def query_param
        value = params[:query].presence || params.dig(:data, :attributes, :query)
        raise ActionController::ParameterMissing, :query if value.blank?

        value
      end

      def filter_query
        Geolocation::QueryParser.call(params[:query]).value
      rescue Geolocation::Errors::InvalidQueryError
        params[:query]
      end
    end
  end
end
