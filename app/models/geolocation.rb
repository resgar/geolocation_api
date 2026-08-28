class Geolocation < ApplicationRecord
  validates :query, presence: true, uniqueness: true
  validates :provider, presence: true
end
