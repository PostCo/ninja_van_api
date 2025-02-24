module NinjaVanAPI
  class Error < StandardError; end

  class UnsupportedCountryCodeError < Error; end
  class AuthenticationError < Error; end
end
