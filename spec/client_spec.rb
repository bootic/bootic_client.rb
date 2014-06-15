require 'spec_helper'
require 'json'

describe BooticClient::Client do
  require 'webmock/rspec'

  describe 'valid response' do
    let(:client) { BooticClient::Client.new(access_token: 'xxx') }
    let(:response_headers) {
      {'Content-Type' => 'application/json', 'Last-Modified' => 'Sat, 07 Jun 2014 12:10:33 GMT'}
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

        let!(:response) { client.get('/v1') }

        it 'returns parsed Faraday response' do
          expect(response).to be_kind_of(Faraday::Response)
          expect(response.status).to eql(200)
          response.body.tap do |b|
            expect(b['_links']['shops']).to eql({'href' => 'https://api.bootic.net/v1/products'})
          end
        end

        context 'and then cached' do
          before do
            @cached_request = stub_request(:get, "https://api.bootic.net/v1")
              .with(headers: {'If-Modified-Since' => 'Sat, 07 Jun 2014 12:10:33 GMT'})
              .to_return(status: 304, body: '', headers: response_headers)
          end

          it 'returns cached response' do
            r = client.get('/v1')
            expect(@cached_request).to have_been_requested

            expect(r.status).to eql(200)
            r.body.tap do |b|
              expect(b['_links']['shops']).to eql({'href' => 'https://api.bootic.net/v1/products'})
            end
          end
        end
      end

      context 'errors' do
        describe 'no access token' do
          it 'raises error' do
            expect{
              BooticClient::Client.new.get('/v1')
            }.to raise_error(BooticClient::NoAccessTokenError)
          end
        end

        describe '500 Server error' do
          before do
            stub_request(:get, "https://api.bootic.net/v1")
              .to_return(status: 500, body: JSON.dump(message: 'Server error'), headers: response_headers)
          end

          it 'raises exception' do
            expect{
              client.get('/v1')
            }.to raise_error(BooticClient::ServerError)
          end
        end

        describe '404 Not Found' do
          before do
            stub_request(:get, "https://api.bootic.net/v1")
              .to_return(status: 404, body: JSON.dump(message: 'not Found'), headers: response_headers)
          end

          it 'raises exception' do
            expect{
              client.get('/v1')
            }.to raise_error(BooticClient::NotFoundError)
          end
        end

        describe '401 Unauthorized' do
          before do
            stub_request(:get, "https://api.bootic.net/v1")
              .to_return(status: 401, body: JSON.dump(message: 'Unauthorised'), headers: response_headers)
          end

          it 'raises exception' do
            expect{
              client.get('/v1')
            }.to raise_error(BooticClient::UnauthorizedError)
          end
        end

        describe '403 Access Forbidden' do
          before do
            stub_request(:get, "https://api.bootic.net/v1")
              .to_return(status: 403, body: JSON.dump(message: 'Access Forbidden'), headers: response_headers)
          end

          it 'raises exception' do
            expect{
              client.get('/v1')
            }.to raise_error(BooticClient::AccessForbiddenError)
          end
        end
      end

    end

    describe '#get_and_wrap' do
      before do
        stub_request(:get, "https://api.bootic.net/v1")
          .with(query: {foo: 'bar'})
          .to_return(status: 200, body: JSON.dump(root_data), headers: response_headers)
      end

      it 'wraps JSON response in entity' do
        wrapper = double('Wrapper Class')
        entity = double('Entity')
        expect(wrapper).to receive(:new).with(root_data, client).and_return entity
        expect(client.get_and_wrap('/v1', wrapper, foo: 'bar')).to eql(entity)
      end
    end

  end
end