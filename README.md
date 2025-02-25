# NinjaVanAPI

A Ruby gem for integrating with NinjaVan's API and handling webhooks in Rails applications.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ninja_van_api'
```

And then execute:

    $ bundle install

## Usage

### Mounting the Webhook Engine

In your Rails application's `config/routes.rb`, mount the webhook engine:

```ruby
Rails.application.routes.draw do
  mount NinjaVanAPI::Engine => '/ninja_van'
end
```

### Configuring Webhooks

Create an initializer in `config/initializers/ninja_van_api.rb`:

```ruby
NinjaVanAPI.configure do |config|
  # Set your webhook job class to process incoming webhooks
  config.webhook_job_class = "NinjaVanWebhookJob"

  # Set your webhook secret (obtained from NinjaVan)
  config.webhook_secret = 'your-webhook-secret'
end
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

The webhook endpoint will be available at `/ninja_van` (or your custom path) and will:

1. Verify the webhook signature using your secret
2. Enqueue the webhook job with the payload

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ninja_van_api. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/ninja_van_api/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the NinjaVanApi project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/ninja_van_api/blob/main/CODE_OF_CONDUCT.md).
