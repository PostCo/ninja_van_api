# frozen_string_literal: true

module NinjaVanAPI
  module Resources
    class Order < Resource
      def create(params = {})
        response = post_request('/orders', body: params)
        Objects::Order.new(parse_response(response))
      end

      def get(tracking_number)
        response = get_request("/orders/#{tracking_number}")
        Objects::Order.new(parse_response(response))
      end

      def update(tracking_number, params = {})
        response = put_request("/orders/#{tracking_number}", body: params)
        Objects::Order.new(parse_response(response))
      end

      def cancel(tracking_number)
        response = delete_request("/orders/#{tracking_number}")
        Objects::Order.new(parse_response(response))
      end
    end
  end
end
