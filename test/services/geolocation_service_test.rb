require "test_helper"

class GeolocationServiceTest < ActiveSupport::TestCase
  def setup
    @valid_ip = "8.8.8.8"
    @invalid_ip = "999.999.999.999"
    @geolocation_service = GeolocationService.new(ip_address: @valid_ip)
  end

  test "should fetch and save geolocation data successfully" do
    VCR.use_cassette("geolocation_service/success") do
      result = @geolocation_service.fetch_and_save

      assert result[:success], "Expected fetch and save to succeed"
      assert_equal @valid_ip, result[:geolocation].ip_address.to_s
      assert_equal "United States", result[:geolocation].details["country_name"]
    end
  end

  test "should return error for invalid IP address" do
    result = GeolocationService.new(ip_address: @invalid_ip).fetch_and_save

    assert_not result[:success], "Expected fetch and save to fail"
    assert_equal "Invalid IP address format", result[:error]
  end

  test "should handle exception during API request" do
    VCR.use_cassette("geolocation_service/network_error") do
      stub_request(:get, /api.ipstack.com/).to_raise(StandardError.new("Network error"))

      geolocation_service = GeolocationService.new(ip_address: @valid_ip)
      result = geolocation_service.fetch_and_save

      assert_not result[:success], "Expected fetch and save to fail"
      assert_equal "Unexpected error occurred", result[:error]
    end
  end
end
