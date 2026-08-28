require "ipaddr"
require "uri"

# Determines whether a client-supplied string is an IP address or a URL/hostname,
# and normalizes it into the form the provider layer expects.
class Geolocation::QueryParser
  Result = Struct.new(:type, :value, keyword_init: true)

  HOSTNAME_REGEX = /\A(?=.{1,253}\z)(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,63}\z/

  def self.call(input)
    new(input).call
  end

  def initialize(input)
    @input = input.to_s.strip
  end

  def call
    raise Geolocation::Errors::InvalidQueryError, "query can't be blank" if input.empty?
    return Result.new(type: :ip, value: input) if ip_address?

    host = extract_host
    unless host && HOSTNAME_REGEX.match?(host)
      raise Geolocation::Errors::InvalidQueryError, "#{input.inspect} is not a valid IP address or URL"
    end

    Result.new(type: :domain, value: host.downcase)
  end

  private

  attr_reader :input

  def ip_address?
    IPAddr.new(input)
    true
  rescue IPAddr::Error
    false
  end

  def extract_host
    candidate = input.include?("://") ? input : "http://#{input}"
    URI.parse(candidate).host
  rescue URI::InvalidURIError
    nil
  end
end
