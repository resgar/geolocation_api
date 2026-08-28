# Orchestrates a geolocation lookup: parses/normalizes the input, returns a
# cached record when we already looked it up, otherwise calls the provider
# and persists the result.
class Geolocation::LookupService
  Outcome = Struct.new(:record, :created, keyword_init: true) do
    def created?
      created
    end
  end

  def self.call(raw_query, client: Geolocation::Client.new)
    new(raw_query, client: client).call
  end

  def initialize(raw_query, client: Geolocation::Client.new)
    @raw_query = raw_query
    @client = client
  end

  def call
    normalized_query = Geolocation::QueryParser.call(raw_query).value

    if (existing = Geolocation.find_by(query: normalized_query))
      return Outcome.new(record: existing, created: false)
    end

    attributes = client.lookup(normalized_query)
    record = Geolocation.create!(attributes.merge(query: normalized_query, provider: client.name))
    Outcome.new(record: record, created: true)
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    # Lost a race with a concurrent request for the same query.
    Outcome.new(record: Geolocation.find_by!(query: normalized_query), created: false)
  end

  private

  attr_reader :raw_query, :client
end
