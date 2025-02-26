# frozen_string_literal: true

require_relative 'ninja_van_api/version'

module NinjaVanAPI
  # Objects
  autoload :Base, 'ninja_van_api/objects/base'
  autoload :Order, 'ninja_van_api/objects/order'

  # Resources
  autoload :BaseResource, 'ninja_van_api/resources/base_resource'
  autoload :OrderResource, 'ninja_van_api/resources/order_resource'

  # Core components
  autoload :Client, 'ninja_van_api/client'
  autoload :Error, 'ninja_van_api/error'
  autoload :UnsupportedCountryCodeError, 'ninja_van_api/error'
  autoload :AuthenticationError, 'ninja_van_api/error'
end
