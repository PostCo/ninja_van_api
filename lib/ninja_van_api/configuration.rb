#
# NinjaVanApi.configure do |config|
#   config.webhook_job_class = MyWebhookJob
#   config.webhook_secret = 'your-webhook-secret'
# end
#
module NinjaVanApi
  class Configuration
    attr_reader :webhook_secrets
    attr_accessor :webhook_job_class

    def webhook_secrets=(secrets)
      @webhook_secrets = secrets.transform_keys { |key| key.to_sym.downcase }
    end

    def get_webhook_secret(country_code)
      @webhook_secrets[country_code.to_sym.downcase]
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
