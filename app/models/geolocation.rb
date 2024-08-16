class Geolocation < ApplicationRecord
  validates :ip_address, presence: true, uniqueness: true
  validates :details, presence: true
end
