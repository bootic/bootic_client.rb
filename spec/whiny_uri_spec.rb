require 'spec_helper'
require "bootic_client/whiny_uri"

describe BooticClient::WhinyURI do
  describe '#expand' do
    let(:uri) {
      described_class.new('http://www.host.com/shops/{id}/{?foo}')
    }

    it 'complains if missing a path segment' do
      expect{
        uri.expand(foo: 1)
      }.to raise_error BooticClient::InvalidURLError
    end

    it 'expands if all path variables provided' do
      expect(uri.expand(id: 123))
        .to eql 'http://www.host.com/shops/123/'
    end

    it 'complains if passing undeclared params' do
      expect{
        uri.expand(id: 123, nope: 'nope')
      }.to raise_error BooticClient::InvalidURLError
    end

    it 'expands if passing declared query variables' do
      expect(uri.expand(id: 123, foo: 'yes'))
        .to eql 'http://www.host.com/shops/123/?foo=yes'
    end
  end
end
