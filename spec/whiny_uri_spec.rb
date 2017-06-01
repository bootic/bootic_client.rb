require 'spec_helper'

require 'uri_template'
module BooticClient
  class WhinyURI
    attr_reader :variables

    def initialize(href)
      @href = href
      @uri = URITemplate.new(href)
      @variables = @uri.variables
    end

    def expand(attrs = {})
      missing = missing_path_variables(attrs)
      if missing.any?
        raise InvalidURLError, "missing: #{missing.join(', ')}"
      end

      undeclared = undeclared_params(attrs)
      if undeclared.any?
        raise InvalidURLError, "undeclared: #{undeclared.join(', ')}"
      end

      uri.expand attrs
    end

    private
    attr_reader :uri, :href

    def path_variables
      @path_variables ||= (
        variables.find_all{ |v|
          Regexp.new("(\/\{#{v}\})|(\{\/#{v}\})") =~ href
        }
      )
    end

    def missing_path_variables(attrs)
      path_variables - attrs.keys.map(&:to_s)
    end

    def undeclared_params(attrs)
      attrs.keys.map(&:to_s) - variables
    end
  end
end

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
