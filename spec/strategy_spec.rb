require 'spec_helper'
require 'bootic_client/strategies/strategy'

describe BooticClient::Strategies::Strategy do
  require 'webmock/rspec'

  let(:config) { BooticClient::Configuration.new }
  subject(:strategy) { described_class.new(config) }

  describe '#request_and_wrap' do
    context 'response is NOT json' do
      it 'returns the raw response' do
        stub_request(:get, 'https://a.server.com/foo')
          .to_return(status: 200, body: 'abc', headers: {'Content-Type' => 'text/plain'})

        resp = strategy.request_and_wrap(:get, 'https://a.server.com/foo')
        expect(resp).to be_a(Faraday::Response)
        expect(resp.body).to eq 'abc'
        expect(resp.status).to eq 200
      end
    end
  end
end
