require 'spec_helper'
require 'json'

describe BooticClient::Client do
  require 'webmock/rspec'

  describe 'valid response' do
    let(:client) { BooticClient::Client.new(access_token: 'xxx') }
    let(:response_headers) {
      {'Content-Type' => 'application/json'}
    }
    let(:root_data) {
      {
        '_links' => {
          'shops' => {'href' => 'https://api.bootic.net/v1/products'}
        },
        'message' => "Hello!"
      }
    }

    describe '#get' do

      context 'fresh' do
        before do
          stub_request(:get, "https://api.bootic.net/v1")
            .to_return(status: 200, body: JSON.dump(root_data), headers: response_headers)
        end

        it 'returns parsed Faraday response' do
          response = client.get('/v1')
          expect(response).to be_kind_of(Faraday::Response)
          expect(response.status).to eql(200)
          response.body.tap do |b|
            expect(b['_links']['shops']).to eql({'href' => 'https://api.bootic.net/v1/products'})
          end
        end

      end

    end

    describe '#get_and_wrap' do
      before do
        stub_request(:get, "https://api.bootic.net/v1")
          .to_return(status: 200, body: JSON.dump(root_data), headers: response_headers)
      end

      it 'wraps JSON response in entity' do
        wrapper = double('Wrapper Class')
        entity = double('Entity')
        expect(wrapper).to receive(:new).with(root_data, client).and_return entity
        expect(client.get_and_wrap('/v1', wrapper)).to eql(entity)
      end
    end

  end
end