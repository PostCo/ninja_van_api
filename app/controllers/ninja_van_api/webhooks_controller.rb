module NinjaVanApi
  class WebhooksController < ActionController::Base
    protect_from_forgery with: :null_session
    before_action :verify_webhook_signature

    def create
      if NinjaVanAPI.configuration.webhook_job_class
        NinjaVanAPI.configuration.webhook_job_class.perform_later(webhook_params.to_h)
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
      # Example: /ninjavan/sg/webhooks -> 'sg'
      country_code = request.path.split("/")[2]&.downcase
      return head :unauthorized unless country_code.present?

      webhook_secret = NinjaVanAPI.configuration.get_webhook_secret(country_code)
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
