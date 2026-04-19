require 'spec_helper'

describe 'Hyperlinked::Strategies::Bearer' do
  require 'webmock/rspec'

  let(:response_headers) { {'Content-Type' => 'application/json'} }
  let(:root_data) {
    {
      '_links' => {
        'a_product' => {'href' => 'https://api.example.com/v1/products/1'}
      },
      'message' => "Hello!"
    }
  }

  let(:product_data) {
    {'title' => 'iPhone 6 Plus'}
  }

  let(:client) { Hyperlinked.client(:bearer, access_token: 'foobar') }

  before do
    Hyperlinked.configure do |c|
      c.api_root = 'https://api.example.com/v1'
    end
  end

  describe '#inspect' do
    it 'is informative' do
      expect(client.inspect).to eql %(#<Hyperlinked::Strategies::Bearer root: https://api.example.com/v1>)
    end
  end

  context 'with missing access token' do
    it 'raises error' do
      expect{
        Hyperlinked.client(:bearer)
      }.to raise_error(ArgumentError)
    end
  end

  context 'with invalid access token' do
    let!(:root_request) do
      stub_request(:get, 'https://api.example.com/v1')
        .with(headers: {"Authorization" => "Bearer foobar"})
        .to_return(status: 401, headers: response_headers, body: JSON.dump(root_data))
    end

    it 'raises an Unauthorized error' do
      expect{ client.root }.to raise_error(Hyperlinked::UnauthorizedError)
      expect(root_request).to have_been_requested
    end
  end

  context 'with valid access token' do
    let!(:root_request) do
      stub_request(:get, 'https://api.example.com/v1')
        .with(headers: {"Authorization" => "Bearer foobar"})
        .to_return(status: 200, headers: response_headers, body: JSON.dump(root_data))
    end

    let!(:product_request) do
      stub_request(:get, 'https://api.example.com/v1/products/1')
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
