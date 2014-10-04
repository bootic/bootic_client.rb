require 'spec_helper'
require 'json'

describe BooticClient::Client do
  require 'webmock/rspec'

  describe 'valid response' do
    let(:root_url) { 'https://api.bootic.net/v1' }
    let(:client) { BooticClient::Client.new(access_token: 'xxx') }
    let(:request_headers) {
      {'Accept' => 'application/json', 'Authorization' => "Bearer xxx"}
    }
    let(:response_headers) {
      {
        'Content-Type' => 'application/json', 
        'Last-Modified' => 'Sat, 07 Jun 2014 12:10:33 GMT',
        'ETag' => '0937dafce10db7b7d405667f9576d26d',
        'Cache-Control' => 'max-age=0, private, must-revalidate'
      }
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
          stub_request(:get, root_url)
            .to_return(status: 200, body: JSON.dump(root_data), headers: response_headers)
        end

        let!(:response) { client.get(root_url) }

        it 'returns parsed Faraday response' do
          expect(response).to be_kind_of(Faraday::Response)
          expect(response.status).to eql(200)
          response.body.tap do |b|
            expect(b['_links']['shops']).to eql({'href' => 'https://api.bootic.net/v1/products'})
          end
        end

        context 'and then cached' do
          before do
            @cached_request = stub_request(:get, root_url)
              .with(headers: {'If-Modified-Since' => 'Sat, 07 Jun 2014 12:10:33 GMT'})
              .to_return(status: 304, body: '', headers: response_headers)
          end

          it 'returns cached response' do
            r = client.get(root_url)
            expect(@cached_request).to have_been_requested

            expect(r.status).to eql(200)
            r.body.tap do |b|
              expect(b['_links']['shops']).to eql({'href' => 'https://api.bootic.net/v1/products'})
            end
          end
        end

        context 'and then cached by ETag' do
          before do
            @cached_request = stub_request(:get, root_url)
              .with(headers: {'If-None-Match' => response_headers['ETag']})
              .to_return(status: 304, body: '', headers: response_headers)
          end

          it 'returns cached response' do
            r = client.get(root_url)
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
              BooticClient::Client.new.get(root_url)
            }.to raise_error(BooticClient::NoAccessTokenError)
          end
        end

        describe '500 Server error' do
          before do
            stub_request(:get, root_url)
              .to_return(status: 500, body: JSON.dump(message: 'Server error'), headers: response_headers)
          end

          it 'raises exception' do
            expect{
              client.get(root_url)
            }.to raise_error(BooticClient::ServerError)
          end
        end

        describe '404 Not Found' do
          before do
            stub_request(:get, root_url)
              .to_return(status: 404, body: JSON.dump(message: 'not Found'), headers: response_headers)
          end

          it 'raises exception' do
            expect{
              client.get(root_url)
            }.to raise_error(BooticClient::NotFoundError)
          end
        end

        describe '401 Unauthorized' do
          before do
            stub_request(:get, root_url)
              .to_return(status: 401, body: JSON.dump(message: 'Unauthorised'), headers: response_headers)
          end

          it 'raises exception' do
            expect{
              client.get(root_url)
            }.to raise_error(BooticClient::UnauthorizedError)
          end
        end

        describe '403 Access Forbidden' do
          before do
            stub_request(:get, root_url)
              .to_return(status: 403, body: JSON.dump(message: 'Access Forbidden'), headers: response_headers)
          end

          it 'raises exception' do
            expect{
              client.get(root_url)
            }.to raise_error(BooticClient::AccessForbiddenError)
          end
        end
      end

    end

    context 'HTTP verbs' do
      describe 'GET' do

        before do
          stub_request(:get, root_url)
            .with(query: {foo: 'bar'}, headers: request_headers)
            .to_return(status: 200, body: JSON.dump(root_data), headers: response_headers)
        end

        it 'GETs response' do
          expect(client.get(root_url, foo: 'bar').body['message']).to eql('Hello!')
        end
      end

      describe 'POST' do
        before do
          stub_request(:post, root_url)
            .with(body: JSON.dump({foo: 'bar'}), headers: request_headers)
            .to_return(status: 201, body: JSON.dump(root_data), headers: response_headers)
        end

        it 'POSTs request and parses response' do
          expect(client.post(root_url, foo: 'bar').body['message']).to eql('Hello!')
        end
      end
 
      [:put, :patch].each do |verb|
        describe verb.to_s.upcase do
          before do
            stub_request(verb, root_url)
              .with(body: JSON.dump({foo: 'bar'}), headers: request_headers)
              .to_return(status: 200, body: JSON.dump(root_data), headers: response_headers)
          end

          it "#{verb.to_s.upcase}s request and parses response" do
            expect(client.send(verb, root_url, foo: 'bar').body['message']).to eql('Hello!')
          end
        end
      end
 
      context 'DELETE' do
        before do
          @delete_requst = stub_request(:delete, root_url)
            .with(headers: request_headers)
            .to_return(status: 200, body: JSON.dump(root_data), headers: response_headers)
        end

        it 'DELETEs request and parses response' do
          expect(client.send(:delete, root_url).status).to eql(200)
          expect(@delete_requst).to have_been_requested
        end
      end
 
    end


  end
end
