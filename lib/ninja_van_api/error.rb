module NinjaVanApi
  class Error < StandardError
  end

  class UnsupportedCountryCodeError < Error
  end
  class AuthenticationError < Error
  end

  class CacheNotDefinedError < Error
  end
end
