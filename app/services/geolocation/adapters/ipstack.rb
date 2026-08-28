require "faraday"

class Geolocation
  module Adapters
    class Ipstack < Base
      BASE_URL = "http://api.ipstack.com"

      def initialize(access_key: Rails.application.credentials.ipstack_api_key, connection: nil)
        @access_key = access_key
        @connection = connection || build_connection
      end

      def lookup(query)
        if access_key.blank?
          raise Geolocation::Errors::NotConfiguredError, "credentials.ipstack_api_key is not set"
        end

        response = connection.get(query.to_s, access_key: access_key, output: "json")
        body = parse_body(response.body)
        handle_provider_error!(body)
        normalize(body)
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
        raise Geolocation::Errors::ProviderUnavailableError, "ipstack request failed: #{e.message}"
      end

      private

      attr_reader :access_key, :connection

      def build_connection
        Faraday.new(url: BASE_URL) do |conn|
          conn.options.timeout = 5
          conn.options.open_timeout = 3
          conn.adapter Faraday.default_adapter
        end
      end

      def parse_body(raw_body)
        raw_body.is_a?(String) ? JSON.parse(raw_body) : raw_body
      rescue JSON::ParserError
        raise Geolocation::Errors::ProviderError, "ipstack returned an unparseable response"
      end

      def handle_provider_error!(body)
        return unless body.is_a?(Hash) && body["success"] == false

        info = body["error"] || {}
        message = info["info"] || "ipstack rejected the request"

        case info["type"].to_s
        when "usage_limit_reached", "rate_limit_reached"
          raise Geolocation::Errors::RateLimitedError, message
        when "invalid_access_key", "missing_access_key", "inactive_user",
             "https_access_restricted", "function_access_restricted"
          raise Geolocation::Errors::NotConfiguredError, message
        when "invalid_ip_address", "invalid_query", "invalid_url"
          raise Geolocation::Errors::InvalidQueryError, message
        else
          raise Geolocation::Errors::ProviderError, message
        end
      end

      def normalize(body)
        {
          ip: body["ip"],
          continent_name: body["continent_name"],
          country_name: body["country_name"],
          country_code: body["country_code"],
          region_name: body["region_name"],
          region_code: body["region_code"],
          city: body["city"],
          zip: body["zip"],
          latitude: body["latitude"],
          longitude: body["longitude"],
          time_zone: body.dig("time_zone", "id"),
          currency: body.dig("currency", "code"),
          raw_data: body
        }
      end
    end
  end
end
