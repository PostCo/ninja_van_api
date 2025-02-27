# frozen_string_literal: true

require "rails"
require_relative "ninja_van_api/version"

module NinjaVanAPI
  class Engine < ::Rails::Engine
    engine_name "ninja_van_api"
    isolate_namespace NinjaVanAPI

    # initializer "ninja_van_api.inflections" do
    #   ActiveSupport::Inflector.inflections(:en) { |inflect| inflect.acronym "NinjaVanAPI" }
    #   Rails.autoloaders.main.inflector.inflect("ninja_van_api" => "NinjaVanAPI")
    # end
  end

  # Objects
  autoload :Base, "ninja_van_api/objects/base"
  autoload :Order, "ninja_van_api/objects/order"

  # Resources
  autoload :BaseResource, "ninja_van_api/resources/base_resource"
  autoload :OrderResource, "ninja_van_api/resources/order_resource"

  # Controllers
  # autoload :WebhookController, "../app/controllers/ninja_van_api/webhook_controller"

  # Core components
  autoload :Client, "ninja_van_api/client"
  autoload :Error, "ninja_van_api/error"
  autoload :UnsupportedCountryCodeError, "ninja_van_api/error"
  autoload :AuthenticationError, "ninja_van_api/error"
end
