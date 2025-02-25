# frozen_string_literal: true

module NinjaVanAPI
  module Objects
    class Order
      attr_accessor :tracking_number, :reference_number, :service_type, :service_level,
                    :requested_tracking_number, :from, :to, :parcel_job,
                    :pickup_service, :delivery_instruction

      def initialize(attributes = {})
        attributes.each do |key, value|
          send("#{key}=", value) if respond_to?("#{key}=")
        end
      end
    end
  end
end
