require "faraday"
require "faraday/net_http"

module NinjaVanApi
  class Client
    BASE_URL = "https://api.ninjavan.co".freeze
    SANDBOX_BASE_URL = "https://api-sandbox.ninjavan.co".freeze
    SUPPORTED_COUNTRY_CODES = %w[SG MY TH ID VN PH MM]

    attr_reader :country_code, :test_mode

    def initialize(client_id:, client_secret:, country_code: "SG", test_mode: false, conn_opts: {})
      @client_id = client_id
      @client_secret = client_secret
      @country_code = country_code
      @test_mode = test_mode
      @conn_opts = conn_opts

      validate_country_code
    end

    def connection
      @connection ||=
        Faraday.new do |conn|
          conn.url_prefix = url_prefix
          conn.options.merge!(@conn_opts)
          # access_token will be evaluated on each request using proc
          conn.request :authorization, :Bearer, -> { access_token }
          conn.request :json
          conn.response :json, content_type: "application/json"
        end
    end

    def orders
      @orders ||= OrderResource.new(self)
    end

    def waybills
      @waybills ||= WaybillResource.new(self)
    end

    def refresh_access_token
      Rails.cache.delete(cache_key)
      fetch_access_token
    end

    private

    def validate_country_code
      if test_mode
        if country_code != "SG"
          raise NinjaVanApi::UnsupportedCountryCodeError, "#{country_code} is not supported on test mode"
        end
      else
        unless SUPPORTED_COUNTRY_CODES.include? country_code
          raise NinjaVanApi::UnsupportedCountryCodeError, "#{country_code} is not supported"
        end
      end
    end

    def access_token
      if Rails.env.development?
        Rails.logger.debug "Access token might be expired. You can refetch the token by calling NinjaVanApi::Client#refresh_access_token. Make sure update the ENV variable NINJAVAN_API_ACCESS_TOKEN"
        ENV.fetch("NINJAVAN_API_ACCESS_TOKEN")
      end

      fetch_access_token if token_expired?

      Rails.cache.read(cache_key)["access_token"]
    end

    def fetch_access_token
      endpoint = "#{url_prefix}/2.0/oauth/access_token"
      response =
        Faraday
          .new
          .post(endpoint) do |req|
            req.headers["Content-Type"] = "application/json"
            req.body = {
              client_id: @client_id,
              client_secret: @client_secret,
              grant_type: "client_credentials",
            }.to_json
          end

      handle_access_token_response(response)
    end

    def token_expired?
      token_info = Rails.cache.read(cache_key)

      return true if token_info.nil?
      # Add a buffer of 6 minutes
      Time.now.utc.to_i >= (token_info["expires"] - 360)
    end

    def handle_access_token_response(response)
      raise NinjaVanApi::AuthenticationError unless response.success?

      token_info = JSON.parse(response.body)
      Rails.cache.write(cache_key, token_info, expires_in: token_info["expires_in"])
      token_info["access_token"]
    end

    def cache_key
      "ninja_van_api_token_#{@client_id}_#{country_code}"
    end

    def url_prefix
      endpoint = test_mode ? SANDBOX_BASE_URL : BASE_URL

      "#{endpoint}/#{country_code.downcase}"
    end
  end
end
