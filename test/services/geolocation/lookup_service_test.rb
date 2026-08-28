require "test_helper"

class Geolocation::LookupServiceTest < ActiveSupport::TestCase
  setup do
    ENV["IPSTACK_API_KEY"] = "test-key"
  end

  test "creates a new record on first lookup" do
    outcome = Geolocation::LookupService.call("8.8.8.8")

    assert outcome.created?
    assert_equal "8.8.8.8", outcome.record.query
    assert_equal "United States", outcome.record.country_name
    assert_equal "ipstack", outcome.record.provider
  end

  test "returns the cached record without calling the provider again" do
    Geolocation.create!(query: "8.8.8.8", provider: "ipstack", country_name: "Cached")

    outcome = Geolocation::LookupService.call("8.8.8.8")

    assert_not outcome.created?
    assert_equal "Cached", outcome.record.country_name
    assert_not_requested :get, /api\.ipstack\.com/
  end

  test "normalizes URLs before looking up or caching" do
    outcome = Geolocation::LookupService.call("https://Example.com/path")

    assert_equal "example.com", outcome.record.query
  end

  test "propagates invalid query errors without hitting the client" do
    assert_raises(Geolocation::Errors::InvalidQueryError) do
      Geolocation::LookupService.call("")
    end

    assert_not_requested :get, /api\.ipstack\.com/
  end
end
