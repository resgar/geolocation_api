# Thin facade in front of the configured geolocation provider. This is the
# single seam the rest of the app depends on, so swapping ipstack for another
# provider later only means adding a class under Geolocation::Providers and
# registering it below (or changing GEOLOCATION_PROVIDER).
class Geolocation::Client
  PROVIDERS = {
    "ipstack" => "Geolocation::Providers::Ipstack"
  }.freeze

  attr_reader :name

  def initialize(provider: ENV.fetch("GEOLOCATION_PROVIDER", "ipstack"))
    @name = provider
    @provider = build_provider(provider)
  end

  def lookup(query)
    provider.lookup(query)
  end

  private

  attr_reader :provider

  def build_provider(provider_name)
    class_name = PROVIDERS.fetch(provider_name) do
      raise Geolocation::Errors::NotConfiguredError, "Unknown geolocation provider: #{provider_name.inspect}"
    end
    class_name.constantize.new
  end
end
