require 'spec_helper'

describe 'BooticClient::Strategies::Bearer' do
  require 'webmock/rspec'

  let(:response_headers) { {'Content-Type' => 'application/json'} }
  let(:root_data) {
    {
      '_links' => {
        'a_product' => {'href' => 'https://api.bootic.net/v1/products/1'}
      },
      'message' => "Hello!"
    }
  }

  let(:product_data) {
    {'title' => 'iPhone 6 Plus'}
  }

  let(:client) { BooticClient.client(:bearer, access_token: 'foobar') }

  describe '#inspect' do
    it 'is informative' do
      expect(client.inspect).to eql %(#<BooticClient::Strategies::Bearer root: https://api.bootic.net/v1>)
    end
  end

  context 'with missing access token' do
    it 'raises error' do
      expect{
        BooticClient.client(:bearer)
      }.to raise_error(ArgumentError)
    end
  end

  context 'with invalid access token' do
    let!(:root_request) do
      stub_request(:get, 'https://api.bootic.net/v1')
        .with(headers: {"Authorization" => "Bearer foobar"})
        .to_return(status: 401, headers: response_headers, body: JSON.dump(root_data))
    end

    it 'raises an Unauthorized error' do
      expect{ client.root }.to raise_error(BooticClient::UnauthorizedError)
      expect(root_request).to have_been_requested
    end
  end

  context 'with valid access token' do
    let!(:root_request) do
      stub_request(:get, 'https://api.bootic.net/v1')
        .with(headers: {"Authorization" => "Bearer foobar"})
        .to_return(status: 200, headers: response_headers, body: JSON.dump(root_data))
    end

    let!(:product_request) do
      stub_request(:get, 'https://api.bootic.net/v1/products/1')
        .with(headers: {"Authorization" => "Bearer foobar"})
        .to_return(status: 200, headers: response_headers, body: JSON.dump(product_data))
    end

    let!(:root) { client.root }

    it 'includes Basic Auth credentials in request' do
      expect(root_request).to have_been_requested
      expect(root.message).to eql('Hello!')
    end

    it 'follows links as normal, including bearer token in every request' do
      product = root.a_product
      expect(product_request).to have_been_requested
      expect(product.title).to eql 'iPhone 6 Plus'
    end
  end
end
