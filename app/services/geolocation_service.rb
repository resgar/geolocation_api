class GeolocationService
  attr_reader :ip_address

  def initialize(ip_address)
    @ip_address = ip_address
  end

  def fetch_and_save
    response = fetch_geolocation_data

    return { success: false, error: "Failed to fetch geolocation data" } unless response.status == 200

    response_body = JSON.parse(response.body)

    return { success: false, error: "Failed to fetch geolocation data" } if response_body["success"] == false

    geolocation = Geolocation.new(ip_address:, details: response_body)

    if geolocation.save
      { success: true, geolocation: }
    else
      { success: false, error: geolocation.errors.full_messages }
    end
  end

  private

  def fetch_geolocation_data
    api_key = ENV["IPSTACK_API_KEY"]
    url = "http://api.ipstack.com/#{ip_address}?access_key=#{api_key}"

    connection = Faraday.new(url:) do |faraday|
      faraday.adapter Faraday.default_adapter
    end

    connection.get
  end
end
