require "test_helper"

class Geolocation::Providers::IpstackTest < ActiveSupport::TestCase
  setup do
    @provider = Geolocation::Providers::Ipstack.new(access_key: "test-key")
  end

  test "normalizes a successful response" do
    stub_request(:get, "http://api.ipstack.com/8.8.8.8")
      .with(query: hash_including(access_key: "test-key"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          ip: "8.8.8.8", country_name: "United States", country_code: "US",
          region_name: "California", city: "Mountain View", zip: "94043",
          latitude: 37.4056, longitude: -122.0775,
          time_zone: { id: "America/Los_Angeles" }, currency: { code: "USD" }
        }.to_json
      )

    result = @provider.lookup("8.8.8.8")

    assert_equal "8.8.8.8", result[:ip]
    assert_equal "United States", result[:country_name]
    assert_equal "America/Los_Angeles", result[:time_zone]
    assert_equal "USD", result[:currency]
    assert_kind_of Hash, result[:raw_data]
  end

  test "raises InvalidQueryError for an unresolvable query" do
    stub_request(:get, "http://api.ipstack.com/not-a-real-host")
      .with(query: hash_including(access_key: "test-key"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { success: false, error: { code: 615, type: "invalid_ip_address", info: "Invalid IP address" } }.to_json
      )

    assert_raises(Geolocation::Errors::InvalidQueryError) { @provider.lookup("not-a-real-host") }
  end

  test "raises RateLimitedError when the plan's usage limit is reached" do
    stub_request(:get, "http://api.ipstack.com/8.8.8.8")
      .with(query: hash_including(access_key: "test-key"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { success: false, error: { code: 104, type: "usage_limit_reached", info: "Usage limit reached" } }.to_json
      )

    assert_raises(Geolocation::Errors::RateLimitedError) { @provider.lookup("8.8.8.8") }
  end

  test "raises NotConfiguredError for an invalid access key" do
    stub_request(:get, "http://api.ipstack.com/8.8.8.8")
      .with(query: hash_including(access_key: "test-key"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { success: false, error: { code: 101, type: "invalid_access_key", info: "Invalid access key" } }.to_json
      )

    assert_raises(Geolocation::Errors::NotConfiguredError) { @provider.lookup("8.8.8.8") }
  end

  test "raises NotConfiguredError when no access key is configured" do
    provider = Geolocation::Providers::Ipstack.new(access_key: nil)
    assert_raises(Geolocation::Errors::NotConfiguredError) { provider.lookup("8.8.8.8") }
  end

  test "raises ProviderUnavailableError on a network timeout" do
    stub_request(:get, "http://api.ipstack.com/8.8.8.8")
      .with(query: hash_including(access_key: "test-key"))
      .to_timeout

    assert_raises(Geolocation::Errors::ProviderUnavailableError) { @provider.lookup("8.8.8.8") }
  end
end
