class GeolocationSerializer
  include JSONAPI::Serializer

  set_type :geolocation

  attributes :query, :ip, :provider, :continent_name, :country_name, :country_code,
             :region_name, :region_code, :city, :zip, :latitude, :longitude,
             :time_zone, :currency, :created_at, :updated_at
end
