require 'faraday'
require 'faraday/net_http'

module NinjaVanAPI
  class Client
    BASE_URL = 'https://api.ninjavan.co'.freeze
    SANDBOX_BASE_URL = 'https://api-sandbox.ninjavan.co'.freeze
    SUPPORTED_COUNTRY_CODES = %w[SG MY TH ID VN PH MM]

    attr_reader :country_code, :test_mode

    def initialize(client_id:, client_key:, country_code: 'SG', test_mode: false, conn_opts: {})
      @client_id = client_id
      @client_key = client_key
      @country_code = country_code
      @test_mode = test_mode
      @conn_opts = conn_opts

      validate_country_code
    end

    def connection
      @connection ||= Faraday.new do |conn|
        conn.url_prefix = url_prefix
        conn.options.merge!(@conn_opts)
        # access_token will be evaluated on each request using proc
        conn.request :authorization, :Bearer, -> { access_token }
        conn.request :json
        conn.response :json
        conn.response :raise_error # Raises error on 4xx and 5xx responses
      end
    end

    private

    def validate_country_code
      if test_mode
        if country_code != 'SG'
          raise NinjaVanAPI::UnsupportedCountryCodeError,
                "#{country_code} is not supported on test mode"
        end
      else
        unless SUPPORTED_COUNTRY_CODES.include? country_code
          raise NinjaVanAPI::UnsupportedCountryCodeError, "#{country_code} is not supported"
        end
      end
    end

    def fetch_access_token
      endpoint = "#{url_prefix}/2.0/oauth/access_token"

      response = Faraday.post(endpoint) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Accept'] = 'application/json'
        req.body = {
          client_id: @client_id,
          client_secret: @client_key,
          grant_type: 'client_credentials'
        }.to_json
      end

      handle_access_token_response(response)
    end

    def access_token
      fetch_access_token if token_expired?

      @token_info['access_token']
    end

    def token_expired?
      return true if @token_info.nil?

      expired_by = @token_info['created_at'] + @token_info['expires_in']

      # Add a buffer of 60 seconds
      Time.now.utc.to_i >= (expired_by - 60)
    end

    def handle_access_token_response(response)
      raise NinjaVanAPI::AuthenticationError unless response.success?

      @token_info = JSON.parse(response.body).merge!({ 'created_at' => Time.now.utc.to_i })
    end

    def url_prefix
      endpoint = test_mode ? SANDBOX_BASE_URL : BASE_URL

      "#{endpoint}/#{country_code.downcase}"
    end
  end
end
