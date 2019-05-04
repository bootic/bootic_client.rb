require 'spec_helper'
require 'bootic_client/strategies/strategy'

describe BooticClient::Strategies::Strategy do
  require 'webmock/rspec'

  let(:config) { BooticClient::Configuration.new }
  subject(:strategy) { described_class.new(config) }

  describe '#request_and_wrap' do
    context 'response is JSON' do
      let(:resp_data) do
        {
          'name' => 'Jason'
        }
      end

      before do
        stub_request(:get, 'https://a.server.com/foo')
          .to_return(status: 200, body: JSON.dump(resp_data), headers: {'Content-Type' => 'application/json'})
      end

      it 'returns the raw response' do
        resp = strategy.request_and_wrap(:get, 'https://a.server.com/foo')
        expect(resp).to be_a(BooticClient::Entity)
        expect(resp.name).to eq 'Jason'
      end
    end

    context 'response is NOT JSON' do
      before do
        stub_request(:get, 'https://a.server.com/foo')
          .to_return(status: 200, body: 'abc', headers: {'Content-Type' => 'text/plain'})
      end

      it 'returns the raw response' do
        resp = strategy.request_and_wrap(:get, 'https://a.server.com/foo')
        expect(resp).to be_a(Faraday::Response)
        expect(resp.body).to eq 'abc'
        expect(resp.status).to eq 200
      end

      it 'uses available request handlers' do
        custom_resp = Struct.new(:message)

        config.request_handlers.add(Proc.new { |resp, client|
          if resp.headers['Content-Type'] == 'text/plain'
            custom_resp.new(resp.body)
          end
        })

        resp = strategy.request_and_wrap(:get, 'https://a.server.com/foo')
        expect(resp).to be_a custom_resp
        expect(resp.message).to eq 'abc'
      end
    end
  end
end
