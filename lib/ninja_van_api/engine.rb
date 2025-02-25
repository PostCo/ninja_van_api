require 'rails/engine'

module NinjaVanAPI
  class Engine < ::Rails::Engine
    isolate_namespace NinjaVanAPI


    config.generators do |g|
      g.test_framework :rspec
      g.assets false
      g.helper false
    end
  end
end
