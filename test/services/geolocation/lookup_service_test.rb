require "test_helper"

class Geolocation::LookupServiceTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :name

    def initialize(response)
      @response = response
      @name = "fake"
    end

    def lookup(_query)
      @response
    end
  end

  class ExplodingClient
    def name
      "exploding"
    end

    def lookup(_query)
      raise "client should not have been called"
    end
  end

  test "creates a new record on first lookup" do
    client = FakeClient.new(ip: "8.8.8.8", country_name: "United States", raw_data: {})

    outcome = Geolocation::LookupService.call("8.8.8.8", client: client)

    assert outcome.created?
    assert_equal "8.8.8.8", outcome.record.query
    assert_equal "United States", outcome.record.country_name
    assert_equal "fake", outcome.record.provider
  end

  test "returns the cached record without calling the provider again" do
    Geolocation.create!(query: "8.8.8.8", provider: "ipstack", country_name: "Cached")
    client = ExplodingClient.new

    outcome = Geolocation::LookupService.call("8.8.8.8", client: client)

    assert_not outcome.created?
    assert_equal "Cached", outcome.record.country_name
  end

  test "normalizes URLs before looking up/caching" do
    client = FakeClient.new(ip: "93.184.216.34", raw_data: {})

    outcome = Geolocation::LookupService.call("https://Example.com/path", client: client)

    assert_equal "example.com", outcome.record.query
  end

  test "propagates invalid query errors without hitting the client" do
    assert_raises(Geolocation::Errors::InvalidQueryError) do
      Geolocation::LookupService.call("", client: ExplodingClient.new)
    end
  end
end
