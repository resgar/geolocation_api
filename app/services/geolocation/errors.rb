class Geolocation
  module Errors
    # Base class for every error this module raises. Rescued centrally in
    # ApplicationController so provider-specific failures never leak as a bare 500.
    class Error < StandardError; end

    # The given input is neither a valid IP address nor a resolvable URL/hostname.
    class InvalidQueryError < Error; end

    # The provider is missing configuration (API key, unsupported plan feature, etc).
    class NotConfiguredError < Error; end

    # The provider rejected the request because of rate/usage limits.
    class RateLimitedError < Error; end

    # The provider could not be reached (network/timeout).
    class ProviderUnavailableError < Error; end

    # The provider responded but with an unexpected/unhandled error.
    class ProviderError < Error; end
  end
end
