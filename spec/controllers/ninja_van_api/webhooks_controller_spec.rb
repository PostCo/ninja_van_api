require "spec_helper"

RSpec.describe NinjaVanApi::WebhooksController, type: :controller do
  routes { NinjaVanApi::Engine.routes }

  let(:webhook_job_class) { "DummyWebhookJob" }
  let(:webhook_secrets) { { sg: "test_sg_secret", my: "test_my_secret" } }
  let(:valid_payload) { { tracking_number: "TEST1234", status: "Delivered" }.to_json }
  let(:country_code) { "sg" }

  # Define a dummy job class for testing
  before do
    stub_const(
      "DummyWebhookJob",
      Class.new do
        def self.perform_later(payload)
          # Mock implementation
        end
      end,
    )

    # Configure NinjaVanApi
    NinjaVanApi.configure do |config|
      config.webhook_job_class = webhook_job_class
      config.webhook_secrets = webhook_secrets
    end

    # Set up request path to include country code
    request.env["PATH_INFO"] = "/#{country_code}"
  end

  after do
    # Reset configuration after each test
    NinjaVanApi.reset_configuration!
  end

  describe "POST #create" do
    context "with valid signature" do
      before do
        # Generate a valid signature
        hash = OpenSSL::HMAC.digest("sha256", webhook_secrets[:sg], valid_payload)
        valid_signature = Base64.encode64(hash).strip
        request.headers["X-Ninjavan-Hmac-Sha256"] = valid_signature
      end

      it "returns http success and enqueues job" do
        expect(DummyWebhookJob).to receive(:perform_later).with(hash_including("tracking_number" => "TEST1234"))
        post :create, body: valid_payload, as: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid signature" do
      before { request.headers["X-Ninjavan-Hmac-Sha256"] = "invalid_signature" }

      it "returns unauthorized status" do
        post :create, body: valid_payload, format: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with missing signature" do
      it "returns unauthorized status" do
        post :create, body: valid_payload, format: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with unsupported country code" do
      let(:country_code) { "unsupported" }

      it "returns unauthorized status" do
        post :create, body: valid_payload, format: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with missing webhook_job_class" do
      before do
        NinjaVanApi.configure do |config|
          config.webhook_job_class = nil
          config.webhook_secrets = webhook_secrets
        end

        # Generate a valid signature
        hash = OpenSSL::HMAC.digest("sha256", webhook_secrets[:sg], valid_payload)
        valid_signature = Base64.encode64(hash).strip
        request.headers["X-Ninjavan-Hmac-Sha256"] = valid_signature
      end

      it "returns unprocessable_entity status" do
        post :create, body: valid_payload, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with invalid webhook_job_class" do
      let(:webhook_job_class) { "NonExistentJob" }

      before do
        # Generate a valid signature
        hash = OpenSSL::HMAC.digest("sha256", webhook_secrets[:sg], valid_payload)
        valid_signature = Base64.encode64(hash).strip
        request.headers["X-Ninjavan-Hmac-Sha256"] = valid_signature
      end

      it "raises ArgumentError" do
        expect { post :create, body: valid_payload, format: :json }.to raise_error(
          ArgumentError,
          /webhook_job_class must be an ActiveJob class name or class that responds to perform_later/,
        )
      end
    end
  end

  describe "#webhook_params" do
    it "permits all parameters except controller and action" do
      controller.params =
        ActionController::Parameters.new(
          controller: "webhooks",
          action: "create",
          tracking_number: "TEST1234",
          status: "Delivered",
        )

      expect(controller.send(:webhook_params).to_h).to eq("tracking_number" => "TEST1234", "status" => "Delivered")
    end
  end
end
