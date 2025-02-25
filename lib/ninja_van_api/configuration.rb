#
# NinjaVanAPI.configure do |config|
#   config.webhook_job_class = MyWebhookJob
#   config.webhook_secret = 'your-webhook-secret'
# end
#
module NinjaVanAPI
  class Configuration
    attr_accessor :webhook_job_class, :webhook_secret

    def initialize
      @webhook_job_class = nil
      @webhook_secret = nil
    end

    def webhook_job_class=(job_class)
      return @webhook_job_class = nil if job_class.nil?

      klass = job_class.is_a?(String) ? job_class.constantize : job_class
      unless klass.is_a?(Class) && klass.respond_to?(:perform_later)
        raise ArgumentError, 'webhook_job_class must be an ActiveJob class name or class that responds to perform_later'
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
