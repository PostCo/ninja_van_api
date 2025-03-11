# frozen_string_literal: true

RSpec.describe NinjaVanApi::OrderResource, type: :request do
  let(:client) do
    NinjaVanApi::Client.new(
      client_id: "test_client_id",
      client_secret: "test_client_secret",
      country_code: "SG",
      test_mode: true,
    )
  end

  let(:base_url) { "https://api-sandbox.ninjavan.co" }

  subject { described_class.new(client) }

  describe "#create" do
    let(:order_params) do
      {
        service_type: "Parcel",
        service_level: "Standard",
        requested_tracking_number: "TEST123",
        from: {
          name: "Sender Name",
          phone_number: "+6591234567",
          email: "sender@example.com",
          address: {
            address1: "123 Sender St",
            city: "Singapore",
            country: "SG",
            postal_code: "123456",
          },
        },
        to: {
          name: "Recipient Name",
          phone_number: "+6598765432",
          email: "recipient@example.com",
          address: {
            address1: "456 Recipient St",
            city: "Singapore",
            country: "SG",
            postal_code: "654321",
          },
        },
      }
    end

    let(:response_body) do
      {
        requested_tracking_number: "TEST123",
        tracking_number: "NINJA123",
        service_type: "Parcel",
        service_level: "Standard",
        reference: {
          merchant_order_number: "SHIP-TEST123",
        },
        from: {
          name: "Sender Name",
          phone_number: "+6591234567",
          email: "sender@example.com",
          address: {
            address1: "123 Sender St",
            address2: "",
            area: "Central",
            city: "Singapore",
            state: "Singapore",
            address_type: "office",
            country: "SG",
            postal_code: "123456",
          },
        },
        to: {
          name: "Recipient Name",
          phone_number: "+6598765432",
          email: "recipient@example.com",
          address: {
            address1: "456 Recipient St",
            address2: "",
            area: "East",
            city: "Singapore",
            state: "Singapore",
            address_type: "home",
            country: "SG",
            postal_code: "654321",
          },
        },
        parcel_job: {
          is_pickup_required: true,
          pickup_service_type: "Scheduled",
          pickup_service_level: "Standard",
          pickup_date: "2025-02-26",
          pickup_timeslot: {
            start_time: "09:00",
            end_time: "18:00",
            timezone: "Asia/Singapore",
          },
          delivery_start_date: "2025-02-26",
          delivery_timeslot: {
            start_time: "09:00",
            end_time: "18:00",
            timezone: "Asia/Singapore",
          },
          dimensions: {
            weight: 1.5,
          },
          items: [{ item_description: "Sample item", quantity: 1, is_dangerous_good: false }],
        },
      }
    end

    context "when the API call is successful" do
      before do
        stub_request(:post, "#{base_url}/sg/4.2/orders").with(body: order_params).to_return(
          status: 200,
          body: response_body.to_json,
          headers: {
            "Content-Type" => "application/json",
          },
        )
      end

      it "creates an order and returns an Order object" do
        order = subject.k(order_params)

        expect(order).to be_a(NinjaVanApi::Order)
        expect(order.tracking_number).to eq("NINJA123")
        expect(order.service_type).to eq("Parcel")
        expect(order.service_level).to eq("Standard")
      end
    end

    context "when the API call fails" do
      before do
        stub_request(:post, "#{base_url}/sg/4.2/orders").with(body: order_params).to_return(
          status: 500,
          body: { error: "API Error" }.to_json,
          headers: {
            "Content-Type" => "application/json",
          },
        )
      end

      it "raises the error" do
        expect { subject.create(order_params) }.to raise_error(NinjaVanApi::Error)
      end
    end
  end

  describe "#cancel" do
    let(:tracking_number) { "NINJA123" }
    let(:response_body) { { "tracking_number" => "NINJA123", "status" => "cancelled" } }

    context "when the API call is successful" do
      before do
        stub_request(:delete, "#{base_url}/sg/2.2/orders/NINJA123").to_return(
          status: 200,
          body: response_body.to_json,
          headers: {
            "Content-Type" => "application/json",
          },
        )
      end

      it "cancels the order and returns an Order object" do
        order = subject.cancel(tracking_number)

        expect(order).to be_a(NinjaVanApi::Order)
        expect(order.tracking_number).to eq("NINJA123")
        expect(order.status).to eq("cancelled")
      end
    end

    context "when the API call fails" do
      before do
        stub_request(:delete, "#{base_url}/sg/2.2/orders/NINJA123").to_return(
          status: 500,
          body: { error: "API Error" }.to_json,
          headers: {
            "Content-Type" => "application/json",
          },
        )
      end

      it "raises the error" do
        expect { subject.cancel(tracking_number) }.to raise_error(NinjaVanApi::Error)
      end
    end
  end
end
