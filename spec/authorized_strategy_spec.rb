require 'spec_helper'
require 'jwt'

describe 'BooticClient::Strategies::Authorized' do
  require 'webmock/rspec'

  let(:client_id) {'aaa'}
  let(:client_secret) {'bbb'}

  def jwt_assertion(expired_token, now)
    JWT.encode({
      iss: client_id,
      aud: 'api',
      prn: expired_token,
      exp: now.utc.to_i + 5
    }, client_secret, 'HS256')
  end

  def stub_api_root(access_token, status, body)
    stub_request(:get, "https://api.bootic.net/v1").
      with(headers: {'Accept'=>'*/*', 'Authorization' => "Bearer #{access_token}"}).
      to_return(status: status, :body => JSON.dump(body))
  end

  def stub_auth(expired_token, status, body)
    now = Time.now
    Time.stub(:now).and_return now

    stub_request(:post, "https://auth.bootic.net/oauth/token").
      with(body: {
        "assertion" => jwt_assertion(expired_token, now), 
        "assertion_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "client_id" => "",
        "client_secret" => "", 
        "grant_type" => "assertion", 
        "scope"=>""
      },
      headers: {
        'Content-Type'=>'application/x-www-form-urlencoded'
      }).
      to_return(status: status, body: JSON.dump(body), headers: {'Content-Type' => 'application/json'})
  end

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
      expect{
        BooticClient.client(:authorized)
      }.to raise_error
    end
  end

  describe 'with no access_token' do
    it 'raises error' do
      expect{
        BooticClient.client(:authorized)
      }.to raise_error
    end
  end

  describe 'with valid client credentials and access_token' do

    let(:client) do
      BooticClient.client(:authorized, access_token: 'abc') do |new_token|
        store[:access_token] = new_token
      end
    end

    before do
      BooticClient.configure do |c|
        c.client_id = client_id
        c.client_secret = client_secret
      end
    end

    context 'with valid token' do
      before do
        @root_request = stub_api_root('abc', 200, message: 'Hello!')
      end

      it 'does not request new token to auth service' do
        root = client.root
        expect(@root_request).to have_been_requested
        expect(root.message).to eql('Hello!')
      end
    end

    context 'with expired token' do
      before do
        @failed_root_request = stub_api_root('abc', 401, message: 'Unauthorized')
        @auth_request = stub_auth('abc', 200, access_token: 'foobar')
        @successful_root_request = stub_api_root('foobar', 200, root_data)
      end

      it 'attempts unauthorised API request, refreshes token from auth an tries again' do
        root = client.root
        expect(@failed_root_request).to have_been_requested
        expect(@auth_request).to have_been_requested
        expect(root.message).to eql('Hello!')
      end

      it 'yields new token to optional block' do
        client.root
        expect(store[:access_token]).to eql('foobar')
      end
    end
  end
end