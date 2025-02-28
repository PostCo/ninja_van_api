# frozen_string_literal: true

require "spec_helper"

RSpec.describe NinjaVanApi::WaybillResource, type: :request do
  let(:client) do
    NinjaVanApi::Client.new(
      client_id: "test_client_id",
      client_secret: "test_client_secret",
      country_code: "SG",
      test_mode: true,
    )
  end

  let(:base_url) { "https://api-sandbox.ninjavan.co" }
  let(:tracking_number) { "TEST123456" }
  let(:pdf_content) { "Sample PDF content" }

  subject { described_class.new(client) }

  describe "#get" do
    context "when successful" do
      before do
        stub_request(:get, "#{base_url}/sg/2.0/reports/waybill").with(
          query: {
            tid: tracking_number,
          },
          headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          },
        ).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/pdf",
            "Content-Disposition" => "attachment; filename=waybill.pdf",
          },
          body: pdf_content,
        )
      end

      it "returns a waybill object with PDF content" do
        waybill = subject.get(tracking_number)
        expect(waybill).to be_a(NinjaVanApi::Waybill)
        expect(waybill.pdf).to eq(pdf_content)
      end

      context "with optional parameters" do
        before do
          stub_request(:get, "#{base_url}/sg/2.0/reports/waybill").with(
            query: {
              tid: tracking_number,
              hide_shipper_details: true,
              orientation: "landscape",
            },
            headers: {
              "Accept" => "*/*",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            },
          ).to_return(
            status: 200,
            headers: {
              "Content-Type" => "application/pdf",
              "Content-Disposition" => "attachment; filename=waybill.pdf",
            },
            body: pdf_content,
          )
        end

        it "includes optional parameters in the request" do
          waybill = subject.get(tracking_number, hide_shipper_details: true, orientation: "landscape")
          expect(waybill).to be_a(NinjaVanApi::Waybill)
          expect(waybill.pdf).to eq(pdf_content)
        end
      end
    end

    context "when the request fails" do
      before do
        stub_request(:get, "#{base_url}/sg/2.0/reports/waybill").with(query: { tid: tracking_number }).to_return(
          status: 404,
          headers: {
            "Content-Type" => "application/json",
          },
          body: { error: "Waybill not found" }.to_json,
        )
      end

      it "raises an error" do
        expect { subject.get(tracking_number) }.to raise_error(NinjaVanApi::Error)
      end
    end
  end
end
