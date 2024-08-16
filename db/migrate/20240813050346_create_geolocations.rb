class CreateGeolocations < ActiveRecord::Migration[7.2]
  def change
    create_table :geolocations do |t|
      t.inet :ip_address, null: false, index: { unique: true }
      t.jsonb :details, null: false

      t.timestamps
    end
  end
end
