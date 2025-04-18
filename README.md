# NinjaVanApi

A Ruby gem for integrating with NinjaVan's API and handling webhooks in Rails applications.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ninja_van_api'
```

And then execute:

    $ bundle install

## Usage

### Retrieving Waybills

```ruby
# Initialize the client
client = NinjaVanApi::Client.new(
  client_id: "your_client_id",
  client_secret: "your_client_secret",
  country_code: "SG",
  test_mode: true
)

# Basic waybill retrieval
waybill = client.waybills.get("TRACKING123")

# Get waybill with optional parameters
waybill = client.waybills.get(
  "TRACKING123",
  hide_shipper_details: true,  # Hide shipper's details in the waybill
  orientation: "landscape"     # Set waybill orientation to landscape
)

# Access the PDF content
pdf_content = waybill.pdf

# Error handling
begin
  waybill = client.waybills.get("INVALID_TRACKING")
rescue NinjaVanApi::Error => e
  puts "Error retrieving waybill: #{e.message}"
end
```

### Mounting the Engine

In your Rails application's `config/routes.rb`, mount the webhook engine. You can mount it multiple times with different country paths. For example:

```ruby
Rails.application.routes.draw do
  # Mount multiple endpoints for different countries
  mount NinjaVanApi::Engine => '/ninja_van/my'
  mount NinjaVanApi::Engine => '/ninja_van/sg'
  mount NinjaVanApi::Engine => '/ninja_van/id'
end
```

### Configuring Webhooks

Create an initializer in `config/initializers/ninja_van_api.rb`. When configuring webhook secrets, you'll need to provide a hash where each key is a country code that corresponds to your mounting paths:

```ruby
NinjaVanApi.configure do |config|
  # Set your webhook job class to process incoming webhooks
  config.webhook_job_class = "NinjaVanWebhookJob"

  # Set your webhook secrets (obtained from NinjaVan)
  # The country code in the mounting path (e.g., 'my', 'sg', 'id')
  # determines which secret is used for verification
  config.webhook_secrets = {
    my: 'your-malaysia-webhook-secret',
    sg: 'your-singapore-webhook-secret',
    id: 'your-indonesia-webhook-secret'
  }
end
```

Note: The country code from your mounting path (e.g., '/ninja_van/my' uses 'MY') determines which webhook secret is used to verify incoming webhooks. The country codes are case-insensitive.

### Creating Orders

First, initialize the NinjaVan API client:

```ruby
client = NinjaVanApi::Client.new(
  client_id: 'your-client-id',
  client_secret: 'your-client-secret',
  test_mode: false # Set to true for sandbox environment
)
```

Then, create an order with the following example:

```ruby
payload = {
  service_type: "Return",
  service_level: "Standard",
  from: {
    name: "John Doe",
    phone_number: "+6591234567",
    email: "john.doe@gmail.com",
    address: {
      address1: "Block 123 Tampines Street 11",
      address2: "#12-345",
      area: "Tampines",
      city: "Singapore",
      state: "Singapore",
      address_type: "office",
      country: "SG",
      postcode: "521123"
    }
  },
  to: {
    name: "Jane Doe",
    phone_number: "+6598765432",
    email: "jane.doe@gmail.com",
    address: {
      address1: "Block 456 Jurong West Street 42",
      address2: "#08-910",
      area: "Jurong West",
      city: "Singapore",
      state: "Singapore",
      address_type: "home",
      country: "SG",
      postcode: "640456"
    }
  },
  parcel_job: {
    is_pickup_required: true,
    pickup_service_type: "Scheduled",
    pickup_service_level: "Standard",
    pickup_date: "2025-02-26",
    pickup_timeslot: {
      start_time: "09:00",
      end_time: "18:00",
      timezone: "Asia/Kuala_Lumpur"
    },
    delivery_start_date: "2025-02-26",
    delivery_timeslot: {
      start_time: "09:00",
      end_time: "18:00",
      timezone: "Asia/Kuala_Lumpur"
    },
    dimensions: {
      weight: 1.5
    },
    items: [
      {
        item_description: "Sample description",
        quantity: 1,
        is_dangerous_good: false
      }
    ]
  }
}

response = client.orders.create(payload)
```

### Processing Webhooks

Create a job to process the webhooks:

```ruby
class NinjaVanWebhookJob < ApplicationJob
  def perform(payload)
    # Process the webhook payload
    # payload contains the webhook data from NinjaVan
  end
end
```

The webhook endpoints will be available at your specified paths (e.g., `/ninja_van/sg`, `/ninja_van/my`, etc.) and will:

1. Verify the webhook signature using your secret
2. Enqueue the webhook job with the payload

## Development

### Setup

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Environment Variables

For development purposes only, create a `.env` file in the root directory with a NinjaVan API access token:

```
NINJAVAN_API_ACCESS_TOKEN=00000000000
```

This token is used exclusively in development to prevent hitting NinjaVan's API request limits. When the token expires:

1. Open the console:

   ```
   bin/console
   ```

2. Refresh the token:

   ```ruby
   # Intialize the client
   client = NinjaVanApi::Client.new(
     client_id: ENV["CLIENT_ID"],
     client_secret: ENV["CLIENT_SECRET"],
     country_code: "SG",
     test_mode: true,
   )

   # Refresh the token
   client.refresh_access_token # => "new_access_token"
   ```

3. Update your `.env` file with the new token

4. Restart your application

Note: These environment variables are automatically loaded when you run `bin/console`. For production, ensure your client credentials (CLIENT_ID and CLIENT_SECRET) are securely set in your deployment environment.

### Authorization Issues

The gem handles token management automatically, including:

- Initial token acquisition
- Automatic token refresh when expired
- Retry mechanisms for failed requests

If you encounter authorization issues:

1. Verify your credentials:

   - Check if CLIENT_ID and CLIENT_SECRET are correct
   - Ensure credentials haven't been revoked by NinjaVan

2. Debug token issues:

   - The gem automatically refreshes expired tokens
   - Check your application logs for token-related errors
   - Verify your system clock is synchronized (important for token validation)

3. Environment-specific troubleshooting:
   - Development: Update your .env file with new credentials if needed
   - Production: Safely update credentials in your environment
   - Always restart your application after credential updates

### Testing

When testing your integration, it's recommended to stub the API requests. Here's an example using RSpec and WebMock:

```ruby
require 'webmock/rspec'

RSpec.describe YourService do
  let(:client) { NinjaVanApi::Client.new(client_id: 'test', client_secret: 'test', country_code: 'SG', test_mode: true) }

  before do
    # Stub authentication request
    stub_request(:post, "https://api.ninjavan.co/SG/2.0/oauth/access_token")
      .to_return(status: 200, body: { access_token: 'test_token' }.to_json)

    # Stub API request
    stub_request(:post, "https://api-sandbox.ninjavan.co/SG/4.2/orders")
      .with(headers: { 'Authorization' => 'Bearer test_token', 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: { tracking_number: 'TEST123' }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  it 'retrieves order information' do
    order_params = {}
    response = client.orders.create(order_params)
    expect(response.tracking_number).to eq('TEST123')
  end
end
```

### Installation

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/PostCo/ninja_van_api. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/ninja_van_api/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the NinjaVanApi project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/ninja_van_api/blob/main/CODE_OF_CONDUCT.md).
