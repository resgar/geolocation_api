ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
require "vcr"

VCR.configure do |config|
  # Deliberately outside test/fixtures/ — `fixtures :all` below recursively
  # globs that directory for ActiveRecord fixtures and chokes on non-AR YAML.
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock

  # Ignore requests to local dev/test servers (like Capybara/Selenium if used)
  config.ignore_localhost = true

  # Prevents real HTTP requests from slipping through when no cassette is active
  config.allow_http_connections_when_no_cassette = false

  # :none means every request must match a pre-recorded interaction in the
  # checked-in cassette; an unmatched request raises instead of silently
  # falling through to a real HTTP call (which is what happened before this
  # was set, recording live ipstack responses into the test suite).
  config.default_cassette_options = { record: :none }

  # Filter sensitive environment variables from cassettes
  # config.filter_sensitive_data('<API_KEY>') { ENV['MY_API_KEY'] }
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Automatically wrap tests in VCR cassettes named after the test method
    def setup
      super
      VCR.insert_cassette(name)
    end

    def teardown
      VCR.eject_cassette
      super
    end
  end
end
