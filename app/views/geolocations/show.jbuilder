json.data do
  json.type "geolocations"
  json.id @geolocation.id.to_s
  json.attributes do
    json.partial! "geolocations/geolocation", geolocation: @geolocation
  end
end
json.links do
  json.self geolocations_url
end
