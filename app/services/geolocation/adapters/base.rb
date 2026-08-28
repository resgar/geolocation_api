class Geolocation
  module Adapters
    # Interface every geolocation provider must implement. To add a new
    # provider: subclass this, implement #lookup, and register it in
    # Geolocation::Client::PROVIDERS.
    class Base
      # @param query [String] an IP address or hostname
      # @return [Hash] normalized attributes matching the Geolocation model
      def lookup(query)
        raise NotImplementedError, "#{self.class} must implement #lookup"
      end
    end
  end
end
