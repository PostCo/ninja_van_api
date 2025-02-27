# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/string"

module NinjaVanApi
  class BaseResource
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def get_request(url, params: {}, headers: {})
      handle_response client.connection.get(url, params, headers)
    end

    def post_request(url, body:, headers: {})
      handle_response client.connection.post(url, body, headers)
    end

    def put_request(url, body:, headers: {})
      handle_response client.connection.put(url, body, headers)
    end

    def delete_request(url, body: {}, headers: {})
      response =
        client
          .connection
          .delete(url) do |request|
            request.body = body
            request.headers = request.headers.merge(headers)
          end

      handle_response response
    end

    private

    def handle_response(response, retry_count = 0)
      error_message = response.body

      case response.status
      when 400
        raise Error, "A bad request or a validation exception has occurred. #{error_message}"
      when 401
        if retry_count.zero?
          # Force token refresh and retry the request once
          client.refresh_access_token
          return retry_request(response.env, retry_count + 1)
        else
          raise Error, "Invalid authorization credentials. #{error_message}"
        end
      when 403
        raise Error, "Connection doesn't have permission to access the resource. #{error_message}"
      when 404
        raise Error, "The resource you have specified cannot be found. #{error_message}"
      when 429
        raise Error, "The API rate limit for your application has been exceeded. #{error_message}"
      when 500
        raise Error,
              "An unhandled error with the server. Contact the NinjaVan team if problems persist. #{error_message}"
      when 503
        raise Error,
              "API is currently unavailable – typically due to a scheduled outage – try again soon. #{error_message}"
      end

      response
    end

    def retry_request(env, retry_count)
      request =
        client
          .connection
          .build_request(env.method.downcase) do |req|
            req.url env.url.to_s
            req.body = env.request_body
            req.headers = env.request_headers
          end

      handle_response(request.run, retry_count)
    end
  end
end
