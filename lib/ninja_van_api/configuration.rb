#
# NinjaVanApi.configure do |config|
#   config.webhook_job_class = MyWebhookJob
#   config.webhook_secret = 'your-webhook-secret'
# end
#
module NinjaVanApi
  class Configuration
    attr_accessor :webhook_job_class
    attr_reader :webhook_secrets

    def initialize
      @webhook_job_class = nil
      @webhook_secrets = {}
    end

    def webhook_secrets=(secrets)
      @webhook_secrets = secrets.transform_keys(&:downcase)
    end

    def get_webhook_secret(country_code)
      @webhook_secrets[country_code.to_s.downcase]
    end

    def webhook_job_class=(job_class)
      return @webhook_job_class = nil if job_class.nil?

      klass = job_class.is_a?(String) ? job_class.constantize : job_class
      unless klass.is_a?(Class) && klass.respond_to?(:perform_later)
        raise ArgumentError, "webhook_job_class must be an ActiveJob class name or class that responds to perform_later"
      end
      @webhook_job_class = klass
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
