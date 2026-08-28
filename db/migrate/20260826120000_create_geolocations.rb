class CreateGeolocations < ActiveRecord::Migration[8.1]
  def change
    create_table :geolocations do |t|
      # Original input supplied by the client, normalized (e.g. downcased host for URLs).
      t.string :query, null: false
      t.string :ip
      t.string :provider, null: false
      t.string :continent_name
      t.string :country_name
      t.string :country_code
      t.string :region_name
      t.string :region_code
      t.string :city
      t.string :zip
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :time_zone
      t.string :currency
      t.jsonb :raw_data, null: false, default: {}

      t.timestamps
    end

    add_index :geolocations, :query, unique: true
  end
end
