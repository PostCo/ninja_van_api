# frozen_string_literal: true

require_relative 'ninja_van_api/version'

module NinjaVanAPI
  autoload :Client, 'ninja_van_api/client'
  autoload :Error, 'ninja_van_api/error'
  autoload :UnsupportedCountryCodeError, 'ninja_van_api/error'
  autoload :AuthenticationError, 'ninja_van_api/error'
  autoload :BaseResource, 'ninja_van_api/resources/base_resource'
end
