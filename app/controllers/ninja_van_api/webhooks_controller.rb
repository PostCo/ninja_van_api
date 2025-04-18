module NinjaVanApi
  class WebhooksController < ActionController::API
    before_action :verify_webhook_signature

    def create
      if NinjaVanApi.configuration.webhook_job_class
        klass =
          begin
            NinjaVanApi.configuration.webhook_job_class.constantize
          rescue NameError
            raise ArgumentError,
                  "webhook_job_class must be an ActiveJob class name or class that responds to perform_later"
          end

        klass.perform_later(webhook_params.to_h)
        head :ok
      else
        head :unprocessable_entity
      end
    end

    private

    def webhook_params
      params.permit!.except(:controller, :action)
    end

    def verify_webhook_signature
      # Extract country code from the request path
      # Example: /sg -> 'sg'
      country_code = request.path.split("/")[-1]&.downcase
      return head :unauthorized unless country_code.present?

      webhook_secret = NinjaVanApi.configuration.get_webhook_secret(country_code)
      return head :unauthorized unless webhook_secret

      signature = request.headers["X-Ninjavan-Hmac-Sha256"]
      return head :unauthorized unless signature.present?

      payload = request.raw_post
      hash = OpenSSL::HMAC.digest("sha256", webhook_secret, payload)
      expected_signature = Base64.encode64(hash).strip

      return head :unauthorized unless Rack::Utils.secure_compare(signature, expected_signature)
    end
  end
end
