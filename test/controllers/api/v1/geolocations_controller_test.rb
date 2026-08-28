require "test_helper"

class Api::V1::GeolocationsControllerTest < ActionDispatch::IntegrationTest
  VALID_TOKEN = "test-api-token"

  setup do
    ENV["API_TOKEN"] = VALID_TOKEN
    ENV["IPSTACK_API_KEY"] = "test-key"
  end

  def auth_headers(token = VALID_TOKEN)
    token ? { "Authorization" => "Bearer #{token}" } : {}
  end

  test "POST create looks up and persists a new geolocation" do
    post api_v1_geolocations_path, params: { query: "8.8.8.8" }, headers: auth_headers, as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "8.8.8.8", body.dig("data", "attributes", "query")
    assert_equal "United States", body.dig("data", "attributes", "country_name")
  end

  test "POST create returns the cached record on a repeat query without re-hitting the provider" do
    post api_v1_geolocations_path, params: { query: "8.8.8.8" }, headers: auth_headers, as: :json
    assert_response :created

    post api_v1_geolocations_path, params: { query: "8.8.8.8" }, headers: auth_headers, as: :json
    assert_response :ok
    assert_requested :get, "http://api.ipstack.com/8.8.8.8", query: hash_including(access_key: "test-key"), times: 1
  end

  test "POST create returns 422 for an invalid query" do
    post api_v1_geolocations_path, params: { query: "not a valid query!!" }, headers: auth_headers, as: :json

    assert_response :unprocessable_content
    assert_equal "422", JSON.parse(response.body)["errors"].first["status"]
  end

  test "POST create returns 400 when query is missing" do
    post api_v1_geolocations_path, params: {}, headers: auth_headers, as: :json

    assert_response :bad_request
  end

  test "POST create returns 502 when the provider is unavailable" do
    VCR.eject_cassette

    VCR.turned_off do
      stub_request(:get, "http://api.ipstack.com/8.8.8.8")
        .with(query: hash_including(access_key: "test-key"))
        .to_timeout

      post api_v1_geolocations_path, params: { query: "8.8.8.8" }, headers: auth_headers, as: :json

      assert_response :bad_gateway
    end
  ensure
    VCR.insert_cassette(name)
  end

  test "GET index lists stored geolocations and supports filtering by query" do
    Geolocation.create!(query: "8.8.8.8", provider: "ipstack")
    Geolocation.create!(query: "example.com", provider: "ipstack")

    get api_v1_geolocations_path, headers: auth_headers, as: :json
    assert_response :success
    assert_equal 2, JSON.parse(response.body)["data"].size

    get api_v1_geolocations_path, params: { query: "8.8.8.8" }, headers: auth_headers
    body = JSON.parse(response.body)
    assert_equal 1, body["data"].size
    assert_equal "8.8.8.8", body["data"].first.dig("attributes", "query")
  end

  test "GET show returns a stored geolocation" do
    geolocation = Geolocation.create!(query: "8.8.8.8", provider: "ipstack")

    get api_v1_geolocation_path(geolocation), headers: auth_headers, as: :json

    assert_response :success
    assert_equal "8.8.8.8", JSON.parse(response.body).dig("data", "attributes", "query")
  end

  test "GET show returns 404 for an unknown id" do
    get api_v1_geolocation_path(id: "does-not-exist"), headers: auth_headers, as: :json

    assert_response :not_found
  end

  test "DELETE destroy removes the geolocation" do
    geolocation = Geolocation.create!(query: "8.8.8.8", provider: "ipstack")

    delete api_v1_geolocation_path(geolocation), headers: auth_headers, as: :json
    assert_response :no_content

    get api_v1_geolocation_path(id: geolocation.id), headers: auth_headers, as: :json
    assert_response :not_found
  end

  test "rejects requests with no bearer token" do
    get api_v1_geolocations_path, headers: auth_headers(nil), as: :json

    assert_response :unauthorized
    assert_equal "401", JSON.parse(response.body)["errors"].first["status"]
  end

  test "rejects requests with the wrong bearer token" do
    get api_v1_geolocations_path, headers: auth_headers("wrong-token"), as: :json

    assert_response :unauthorized
  end

  test "rejects every request when no api_token is configured" do
    ENV["API_TOKEN"] = nil

    get api_v1_geolocations_path, headers: auth_headers, as: :json

    assert_response :unauthorized
  end

  test "accepts a valid bearer token" do
    get api_v1_geolocations_path, headers: auth_headers, as: :json

    assert_response :success
  end
end
