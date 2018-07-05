require 'spec_helper'

describe 'BooticClient::Strategies::ClientCredentials' do
  require 'webmock/rspec'

  let(:store){ Hash.new }
  let(:root_data) {
    {
      '_links' => {
        'shops' => {'href' => 'https://api.bootic.net/v1/products'}
      },
      'message' => "Hello!"
    }
  }

  describe 'with missing client credentials' do
    it 'raises error' do
      allow(BooticClient).to receive(:client_id).and_return nil
      expect{
        BooticClient.client(:client_credentials, scope: 'admin')
      }.to raise_error(ArgumentError)
    end
  end

  describe 'with valid client credentials' do

    def stub_auth(status, body)
      stub_request(:post, "https://auth.bootic.net/oauth/token").
        with(body: {"grant_type"=>"client_credentials", client_id: "aaa", client_secret: "bbb", 'scope' => 'admin'}).
        to_return(status: status, body: JSON.dump(body), headers: {'Content-Type' => 'application/json'})
    end

    def stub_api_root(access_token, status, body)
      stub_request(:get, "https://api.bootic.net/v1").
        with(headers: {'Accept'=>'application/json', 'Authorization'=>"Bearer #{access_token}"}).
        to_return(status: status, body: JSON.dump(body))
    end

    before do
      BooticClient.configure do |c|
        c.client_id = 'aaa'
        c.client_secret = 'bbb'
      end
    end

    context 'with no previous access token' do
      let(:client) do
        BooticClient.client(:client_credentials, scope: 'admin') do |new_token|
          store[:access_token] = new_token
        end
      end

      before do
        @auth_request = stub_auth(200, access_token: 'foobar')
        stub_api_root 'foobar', 200, root_data
      end

      it 'requests access token via client_credentials flow' do
        root = client.root
        expect(@auth_request).to have_been_requested
        expect(root.message).to eql('Hello!')
      end

      it 'yields new token to optional block' do
        client.root
        expect(store[:access_token]).to eql('foobar')
      end
    end

    context 'with an expired access token' do
      let(:client) do
        BooticClient.client(:client_credentials, scope: 'admin', access_token: 'abc') do |new_token|
          store[:access_token] = new_token
        end
      end

      before do
        @failed_root_request = stub_api_root('abc', 401, message: 'Unauthorized')
        @auth_request = stub_auth(200, access_token: 'foobar')
        @successful_root_request = stub_api_root('foobar', 200, root_data)
      end

      it 'attempts unauthorised API request, gets token from auth an tries again' do
        root = client.root
        expect(@failed_root_request).to have_been_requested
        expect(@auth_request).to have_been_requested
        expect(@successful_root_request).to have_been_requested
        expect(root.message).to eql('Hello!')
      end

      it 'yields new token to optional block' do
        client.root
        expect(store[:access_token]).to eql('foobar')
      end

      it 'updates internal access token' do
        client.root
        expect(client.options[:access_token]).to eql('foobar')
      end
    end
  end

end
