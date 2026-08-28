require "test_helper"

class Geolocation::Providers::IpstackTest < ActiveSupport::TestCase
  setup do
    @provider = Geolocation::Providers::Ipstack.new(access_key: "test-key")
  end

  test "normalizes a successful response" do
    result = @provider.lookup("8.8.8.8")

    assert_equal "8.8.8.8", result[:ip]
    assert_equal "United States", result[:country_name]
    assert_equal "America/Los_Angeles", result[:time_zone]
    assert_equal "USD", result[:currency]
    assert_kind_of Hash, result[:raw_data]
  end

  test "raises InvalidQueryError for an unresolvable query" do
    assert_raises(Geolocation::Errors::InvalidQueryError) { @provider.lookup("not-a-real-host") }
  end

  test "raises RateLimitedError when the plan's usage limit is reached" do
    assert_raises(Geolocation::Errors::RateLimitedError) { @provider.lookup("8.8.8.8") }
  end

  test "raises NotConfiguredError for an invalid access key" do
    assert_raises(Geolocation::Errors::NotConfiguredError) { @provider.lookup("8.8.8.8") }
  end

  test "raises NotConfiguredError when no access key is configured" do
    provider = Geolocation::Providers::Ipstack.new(access_key: nil)
    assert_raises(Geolocation::Errors::NotConfiguredError) { provider.lookup("8.8.8.8") }
  end

  test "raises ProviderUnavailableError on a network timeout" do
    # VCR cassettes represent completed HTTP exchanges, not connection
    # failures, so there's nothing to record/play back here — stub the
    # timeout directly with WebMock instead, just for this one test. VCR
    # won't turn off while a cassette is in use, so eject the auto-inserted
    # one first and put a (never-touched) one back before teardown ejects it.
    VCR.eject_cassette
    VCR.turn_off!(ignore_cassettes: true)

    stub_request(:get, "http://api.ipstack.com/8.8.8.8")
      .with(query: hash_including(access_key: "test-key"))
      .to_timeout

    assert_raises(Geolocation::Errors::ProviderUnavailableError) { @provider.lookup("8.8.8.8") }
  ensure
    VCR.turn_on!
    VCR.insert_cassette(name)
  end
end
