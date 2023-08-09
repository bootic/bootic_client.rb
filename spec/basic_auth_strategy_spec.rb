require 'spec_helper'

describe 'BooticClient::Strategies::BasicAuth' do
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

  let(:client) { BooticClient.client(:basic_auth, username: 'foo', password: 'bar') }

  describe '#inspect' do
    it 'is informative' do
      expect(client.inspect).to eql %(#<BooticClient::Strategies::BasicAuth root: https://api.bootic.net/v1 username: foo>)
    end
  end

  context 'with missing credentials' do
    it 'raises error' do
      expect{
        BooticClient.client(:basic_auth)
      }.to raise_error(ArgumentError)
    end
  end

  context 'with invalid BasicAuth credentials' do
    let!(:root_request) do
      stub_request(:get, 'https://api.bootic.net/v1')
        .with(basic_auth: ['foo', 'bar'])
        .to_return(status: 401, headers: response_headers, body: JSON.dump(root_data))
    end

    it 'raises an Unauthorized error' do
      expect{ client.root }.to raise_error(BooticClient::UnauthorizedError)
      expect(root_request).to have_been_requested
    end
  end

  context 'with valid BasicAuth credentials' do
    let!(:root_request) do
      stub_request(:get, 'https://api.bootic.net/v1')
        .with(basic_auth: ['foo', 'bar'])
        .to_return(status: 200, headers: response_headers, body: JSON.dump(root_data))
    end

    let!(:product_request) do
      stub_request(:get, 'https://api.bootic.net/v1/products/1')
        .with(basic_auth: ['foo', 'bar'])
        .to_return(status: 200, headers: response_headers, body: JSON.dump(product_data))
    end

    let!(:root) { client.root }

    it 'includes Basic Auth credentials in request' do
      expect(root_request).to have_been_requested
      expect(root.message).to eql('Hello!')
    end

    it 'follows links as normal, including Basic Auth in every request' do
      product = root.a_product
      expect(product_request).to have_been_requested
      expect(product.title).to eql 'iPhone 6 Plus'
    end
  end
end
