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
      exp: now.utc.to_i + 30
    }, client_secret, 'HS256')
  end

  def stub_api_root(access_token, status, body)
    stub_request(:get, "https://api.bootic.net/v1").
      with(headers: {'Accept'=>'application/json', 'Authorization' => "Bearer #{access_token}"}).
      to_return(status: status, :body => JSON.dump(body))
  end

  def stub_auth(expired_token, status, body, client_id: '', client_secret: '', scope: '')
    now = Time.now
    allow(Time).to receive(:now).and_return now

    stub_request(:post, "https://auth.bootic.net/oauth/token").
      with(body: {
        "assertion" => jwt_assertion(expired_token, now),
        "assertion_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "client_id" => client_id,
        "client_secret" => client_secret,
        "grant_type" => "assertion",
        "scope"=>scope
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
        'shops' => {'href' => 'https://api.bootic.net/v1/shops'}
      },
      'message' => "Hello!"
    }
  }

  describe 'with missing client credentials' do
    it 'raises error' do
      expect{
        BooticClient.client(:authorized)
      }.to raise_error(ArgumentError)
    end
  end

  describe 'with no access_token' do
    it 'raises error' do
      expect{
        BooticClient.client(:authorized)
      }.to raise_error(ArgumentError)
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

    context 'without a block' do
      it 'is valid' do
        expect{
          BooticClient.client(:authorized, access_token: 'abc')
        }.not_to raise_error
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

      it 'attempts unauthorised API request, refreshes token from auth and tries again' do
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

    context 'expired token, other resources' do
      before do
        stub_api_root('abc', 200, root_data)
        @unauthorized_request = stub_request(:get, "https://api.bootic.net/v1/shops").
          with(headers: {'Accept'=>'application/json', 'Authorization' => "Bearer abc"}).
          to_return(status: 401, :body => JSON.dump(message: 'authorized'))
        @auth_request = stub_auth('abc', 200, access_token: 'validtoken')

        @authorized_request = stub_request(:get, "https://api.bootic.net/v1/shops").
          with(headers: {'Accept'=>'application/json', 'Authorization' => "Bearer validtoken"}).
          to_return(status: 200, :body => JSON.dump(title: 'All shops'))
        @root = client.root
      end

      it 'attempts unauthorized API request to shops, refreshes token and tries again' do
        shops = @root.shops
        expect(@unauthorized_request).to have_been_requested
        expect(@auth_request).to have_been_requested
        expect(@authorized_request).to have_been_requested
        expect(shops.title).to eql('All shops')
      end
    end

    describe '#from_hash' do
      it 'builds and returns an entity' do
        entity = client.from_hash('name' =>  'foo', '_links' => {'delete' => {'href' => '/foo/bar'}})
        expect(entity).to be_kind_of(BooticClient::Entity)
        expect(entity.name).to eql('foo')
        expect(entity.can?(:delete)).to be true
      end
    end

    describe '#from_url' do
      it 'builds and returns an entity' do
        authorized_request = stub_request(:get, "https://api.bootic.net/v1/shops").
          to_return(status: 200, :body => JSON.dump(title: 'All shops'))

        entity = client.from_url('https://api.bootic.net/v1/shops')
        expect(entity).to be_kind_of(BooticClient::Entity)
        expect(entity.title).to eql('All shops')
      end
    end
  end
end
