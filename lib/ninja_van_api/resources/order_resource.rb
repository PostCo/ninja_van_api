# frozen_string_literal: true

module NinjaVanAPI
  class OrderResource < BaseResource
    def create(params = {})
      response = post_request("4.2/orders", body: params)
      Order.new(response.body)
    end

    def cancel(tracking_number)
      response = delete_request("2.2/orders/#{tracking_number}")
      Order.new(response.body)
    end
  end
end
