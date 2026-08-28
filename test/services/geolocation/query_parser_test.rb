require "test_helper"

class Geolocation::QueryParserTest < ActiveSupport::TestCase
  test "recognizes an IPv4 address" do
    result = Geolocation::QueryParser.call("8.8.8.8")
    assert_equal :ip, result.type
    assert_equal "8.8.8.8", result.value
  end

  test "recognizes an IPv6 address" do
    result = Geolocation::QueryParser.call("2001:4860:4860::8888")
    assert_equal :ip, result.type
  end

  test "extracts the host from a full URL" do
    result = Geolocation::QueryParser.call("https://www.example.com/some/path?x=1")
    assert_equal :domain, result.type
    assert_equal "www.example.com", result.value
  end

  test "accepts a bare hostname without a scheme" do
    result = Geolocation::QueryParser.call("example.com")
    assert_equal :domain, result.type
    assert_equal "example.com", result.value
  end

  test "downcases the hostname" do
    result = Geolocation::QueryParser.call("Example.COM")
    assert_equal "example.com", result.value
  end

  test "raises for a blank query" do
    assert_raises(Geolocation::Errors::InvalidQueryError) { Geolocation::QueryParser.call("") }
    assert_raises(Geolocation::Errors::InvalidQueryError) { Geolocation::QueryParser.call("   ") }
  end

  test "raises for garbage input" do
    assert_raises(Geolocation::Errors::InvalidQueryError) { Geolocation::QueryParser.call("not a url") }
    assert_raises(Geolocation::Errors::InvalidQueryError) { Geolocation::QueryParser.call("999.999.999.999") }
  end
end
