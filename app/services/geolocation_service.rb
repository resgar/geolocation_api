class GeolocationService
  def initialize(ip_address: nil, url: nil)
    resolved_ip = resolve_ip_address(url) if url.present?
    @ip_address = resolved_ip || ip_address
  end

  def fetch_and_save
    validate_ip_address

    response = fetch_geolocation_data

    return { success: false, error: "Failed to fetch geolocation data" } unless response.status == 200

    response_body = JSON.parse(response.body)

    return { success: false, error: "Failed to fetch geolocation data" } if response_body["success"] == false

    geolocation = Geolocation.new(ip_address: @ip_address, details: response_body)

    if geolocation.save
      { success: true, geolocation: }
    else
      { success: false, error: geolocation.errors.full_messages }
    end

  rescue ArgumentError => e
    { success: false, error: e.message }
  rescue StandardError => e
    Rails.logger.error("Unexpected error: #{e.message}")
    { success: false, error: "Unexpected error occurred" }
  end

  private

  def fetch_geolocation_data
    api_key = Rails.application.credentials.api_key
    url = "http://api.ipstack.com/#{@ip_address}?access_key=#{api_key}"

    begin
      connection = Faraday.new(url:) do |faraday|
        faraday.adapter Faraday.default_adapter
      end

      connection.get
    rescue StandardError => e
      Rails.logger.error("Error fetching geolocation data: #{e.message}")
      nil
    end
  end

  def validate_ip_address
    IPAddr.new(@ip_address)
  rescue IPAddr::InvalidAddressError
    raise ArgumentError, "Invalid IP address format"
  end

  def resolve_ip_address(url)
    Resolv.getaddress(url)
  rescue Resolv::ResolvError
    render_bad_request("Invalid URL format")
  end
end
