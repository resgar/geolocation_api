# Seeds a handful of sample geolocation records so the API has something to
# return out of the box, without requiring a real ipstack_api_key. Real
# lookups (POST /api/v1/geolocations) still hit the configured provider.

[
  {
    query: "8.8.8.8", ip: "8.8.8.8", provider: "ipstack",
    continent_name: "North America", country_name: "United States", country_code: "US",
    region_name: "California", region_code: "CA", city: "Mountain View", zip: "94043",
    latitude: 37.4056, longitude: -122.0775, time_zone: "America/Los_Angeles", currency: "USD"
  },
  {
    query: "1.1.1.1", ip: "1.1.1.1", provider: "ipstack",
    continent_name: "Oceania", country_name: "Australia", country_code: "AU",
    region_name: "Queensland", region_code: "QLD", city: "South Brisbane", zip: "4101",
    latitude: -27.4766, longitude: 153.0166, time_zone: "Australia/Brisbane", currency: "AUD"
  },
  {
    query: "github.com", ip: "140.82.112.3", provider: "ipstack",
    continent_name: "North America", country_name: "United States", country_code: "US",
    region_name: "California", region_code: "CA", city: "San Francisco", zip: "94107",
    latitude: 37.7697, longitude: -122.3933, time_zone: "America/Los_Angeles", currency: "USD"
  }
].each do |attributes|
  Geolocation.find_or_create_by!(query: attributes[:query]) do |record|
    record.assign_attributes(attributes.merge(raw_data: attributes.stringify_keys))
  end
end

puts "Seeded #{Geolocation.count} geolocation record(s)."
