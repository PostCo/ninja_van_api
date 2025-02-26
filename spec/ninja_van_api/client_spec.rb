require 'pry'

RSpec.describe NinjaVanAPI::Client do
  subject do
    NinjaVanAPI::Client.new(
      client_id: ENV['client_id'],
      client_secret: ENV['client_secret'],
      country_code: country_code,
      test_mode: test_mode
    )
  end
  let(:test_mode) { true }
  let(:country_code) { 'SG' }

  describe '#connection' do
    it 'uses the correct adapter and middlewares' do
      connection = subject.connection
      expect(connection.builder.adapter).to eq(::Faraday::Adapter::NetHttp)
      expect(connection.builder.handlers).to include(Faraday::Request::Json, Faraday::Response::Json,
                                                     Faraday::Response::RaiseError)
    end

    context 'prefix_url' do
      context 'in test mode' do
        it 'uses the sandbox url' do
          connection = subject.connection
          expect(connection.url_prefix.to_s).to eq('https://api-sandbox.ninjavan.co/sg')
        end
      end

      context 'in production mode' do
        let(:test_mode) { false }
        it 'uses the production url' do
          connection = subject.connection
          expect(connection.url_prefix.to_s).to eq('https://api.ninjavan.co/sg')
        end
      end
    end
  end
end
