require "test_helper"

class GeolocationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @valid_ip = "8.8.8.8"
    @invalid_ip = "invalid_ip"
  end

  test "should create geolocation" do
    VCR.use_cassette("geolocation_valid_ip") do
      assert_difference("Geolocation.count", 1) do
        post geolocations_url, params: { geolocation: { ip_address: @valid_ip } }, as: :json
      end

      assert_response :created
      json_response = JSON.parse(response.body)
      assert_equal @valid_ip, json_response["data"]["attributes"]["ip"]
      assert_equal 40.54, json_response["data"]["attributes"]["details"]["latitude"].round(2)
      assert_equal(-82.13, json_response["data"]["attributes"]["details"]["longitude"].round(2))
    end
  end

  test "should create geolocation with url" do
    url = "www.google.com"
    ip_address =  Resolv.getaddress(url)
    VCR.use_cassette("geolocation_valid_url", match_requests_on: [ :method, :host ]) do
      assert_difference("Geolocation.count", 1) do
        post geolocations_url, params: { geolocation: { url: } }, as: :json
      end

      json_response = JSON.parse(response.body)
      assert_response :created
      assert_equal ip_address, json_response["data"]["attributes"]["ip"]
    end
  end

  test "should not create geolocation with invalid IP address" do
    VCR.use_cassette("geolocation_invalid_ip") do
      assert_no_difference("Geolocation.count") do
        post geolocations_url, params: { geolocation: { ip_address: @invalid_ip } }, as: :json
      end

      assert_response :unprocessable_entity
      json_response = JSON.parse(response.body)
      assert_equal "Invalid IP address format", json_response["errors"][0]["detail"]
    end
  end

  test "should show geolocation data" do
    @geolocation = Geolocation.create!(
      ip_address: "192.168.1.1",
      details: {
        "ip": "192.168.1.1",
        "type": "ipv4",
        "latitude": 37.7749,
        "longitude": -122.4194
      }.to_json
    )
    get geolocations_url, params: { ip_address: "192.168.1.1" }
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal "geolocations", json_response["data"]["type"]
    assert_equal @geolocation.id.to_s, json_response["data"]["id"]
    assert_equal "192.168.1.1", json_response["data"]["attributes"]["ip"]
  end

  test "should show geolocation data with url" do
    url = "www.google.com"
    ip_address =  Resolv.getaddress(url)
    @geolocation = Geolocation.create!(
      ip_address:,
      details: {
        "ip": ip_address,
        "type": "ipv4",
        "latitude": 37.7749,
        "longitude": -122.4194
      }.to_json
    )
    get geolocations_url, params: { url: }
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal "geolocations", json_response["data"]["type"]
    assert_equal @geolocation.id.to_s, json_response["data"]["id"]
    assert_equal ip_address, json_response["data"]["attributes"]["ip"]
  end


  test "should return not found for not availale IP address" do
    get geolocations_url, params: { ip_address: "99.99.99.99" }
    assert_response :not_found

    json_response = JSON.parse(response.body)
    assert_equal "404", json_response["errors"][0]["status"]
    assert_equal "Not Found", json_response["errors"][0]["title"]
    assert_equal "Geolocation data not found for IP address 99.99.99.99", json_response["errors"][0]["detail"]
  end

  test "should return bad request for invalid IP address" do
    get geolocations_url, params: { ip_address: "999.999.999.999" }
    assert_response :bad_request

    json_response = JSON.parse(response.body)
    assert_equal "400", json_response["errors"][0]["status"]
    assert_equal "Bad Request", json_response["errors"][0]["title"]
  end

  test "should successfully delete geolocation" do
    @geolocation = Geolocation.create!(
      ip_address: @valid_ip,
      details: {
        "ip": @valid_ip,
        "type": "ipv4"
      }.to_json
    )

    assert_difference("Geolocation.count", -1) do
      delete geolocations_url, params: { ip_address: @valid_ip }, as: :json
    end

    assert_response :no_content
  end

  test "should return not found when deleting non-existent geolocation" do
    assert_no_difference("Geolocation.count") do
      delete geolocations_url, params: { ip_address: @valid_ip }, as: :json
    end

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal "Geolocation data not found for IP address #{@valid_ip}", json_response["errors"][0]["detail"]
  end
end
