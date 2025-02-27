require "faraday"
require "faraday/net_http"

module NinjaVanAPI
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
      if defined?(Rails) && Rails.env.development?
        @token_info = { "access_token" => ENV["NINJAVAN_API_ACCESS_TOKEN"], "expires" => Time.now.utc.to_i + 3600 }
      end

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

    private

    def validate_country_code
      if test_mode
        if country_code != "SG"
          raise NinjaVanAPI::UnsupportedCountryCodeError, "#{country_code} is not supported on test mode"
        end
      else
        unless SUPPORTED_COUNTRY_CODES.include? country_code
          raise NinjaVanAPI::UnsupportedCountryCodeError, "#{country_code} is not supported"
        end
      end
    end

    def access_token
      fetch_access_token if token_expired?

      if defined?(Rails) && Rails.respond_to?(:cache)
        Rails.cache.read(cache_key)["access_token"]
      else
        @token_info["access_token"]
      end
    end

    def refresh_access_token
      @token_info = nil
      Rails.cache.delete(cache_key) if defined?(Rails) && Rails.respond_to?(:cache)
      fetch_access_token
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

      raise NinjaVanAPI::AuthenticationError, response.body unless response.success?

      JSON.parse(response.body)["access_token"]

      response =
        Faraday.post(endpoint) do |req|
          req.headers["Content-Type"] = "application/json"
          req.headers["Accept"] = "application/json"
          req.body = { client_id: @client_id, client_secret: @client_secret, grant_type: "client_credentials" }.to_json
        end

      handle_access_token_response(response)
    end

    def access_token
      fetch_access_token if token_expired?

      if defined?(Rails) && Rails.respond_to?(:cache)
        Rails.cache.read(cache_key)["access_token"]
      else
        @token_info["access_token"]
      end
    end

    def token_expired?
      token_info =
        if defined?(Rails) && Rails.respond_to?(:cache)
          Rails.cache.read(cache_key)
        else
          @token_info
        end

      return true if token_info.nil?

      # Add a buffer of 6 minutes
      Time.now.utc.to_i >= (token_info["expires"] - 360)
    end

    def handle_access_token_response(response)
      raise NinjaVanAPI::AuthenticationError unless response.success?

      token_info = JSON.parse(response.body)

      if defined?(Rails) && Rails.respond_to?(:cache)
        Rails.cache.write(cache_key, token_info, expires_in: token_info["expires_in"])
      else
        @token_info = token_info
      end
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
