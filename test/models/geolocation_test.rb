require "test_helper"

class GeolocationTest < ActiveSupport::TestCase
  test "valid with a query and provider" do
    geolocation = Geolocation.new(query: "8.8.8.8", provider: "ipstack")
    assert geolocation.valid?
  end

  test "invalid without a query" do
    geolocation = Geolocation.new(query: nil, provider: "ipstack")
    assert_not geolocation.valid?
    assert_includes geolocation.errors[:query], "can't be blank"
  end

  test "invalid without a provider" do
    geolocation = Geolocation.new(query: "8.8.8.8", provider: nil)
    assert_not geolocation.valid?
    assert_includes geolocation.errors[:provider], "can't be blank"
  end

  test "query is unique" do
    Geolocation.create!(query: "8.8.8.8", provider: "ipstack")
    duplicate = Geolocation.new(query: "8.8.8.8", provider: "ipstack")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:query], "has already been taken"
  end
end
