module AddressResolution
  extend ActiveSupport::Concern

  included do
    def resolve_address(address)
      raise ActionController::ParameterMissing, :address if address.blank?

      URI.parse(address) # Validates address
      resolved_address = Resolv.getaddress(address)
      IPAddr.new(resolved_address).to_s
    end
  end
end
