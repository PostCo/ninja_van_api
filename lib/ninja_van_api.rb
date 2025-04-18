# frozen_string_literal: true

require "rails"
require_relative "ninja_van_api/version"

module NinjaVanApi
  class Engine < ::Rails::Engine
    engine_name "ninja_van_api"
    isolate_namespace NinjaVanApi
  end

  require "ninja_van_api/configuration"

  # Objects
  autoload :Base, "ninja_van_api/objects/base"
  autoload :Order, "ninja_van_api/objects/order"
  autoload :Waybill, "ninja_van_api/objects/waybill"

  # Resources
  autoload :BaseResource, "ninja_van_api/resources/base_resource"
  autoload :OrderResource, "ninja_van_api/resources/order_resource"
  autoload :WaybillResource, "ninja_van_api/resources/waybill_resource"

  # Core components
  autoload :Client, "ninja_van_api/client"
  autoload :Error, "ninja_van_api/error"
  autoload :UnsupportedCountryCodeError, "ninja_van_api/error"
  autoload :AuthenticationError, "ninja_van_api/error"
end
