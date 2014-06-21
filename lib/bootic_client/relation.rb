require 'uri_template'
require "bootic_client/entity"

module BooticClient

  class Relation

    GET = 'get'.freeze

    def initialize(attrs, client, wrapper_class = Entity)
      @attrs, @client, @wrapper_class = attrs, client, wrapper_class
    end

    def inspect
      %(#<#{self.class.name} #{attrs.inspect}>)
    end

    def href
      attrs['href']
    end

    def templated?
      !!attrs['templated']
    end

    def name
      attrs['name']
    end

    def title
      attrs['title']
    end

    def type
      attrs['type']
    end

    def docs
      attrs['docs']
    end

    def transport_method
      @transport_method ||= attrs['method'] || GET
    end

    def run(opts = {})
      self.send(transport_method, opts)
    end

    def get(opts = {})
      if templated?
        client.get_and_wrap uri.expand(opts), wrapper_class
      else
        client.get_and_wrap href, wrapper_class, opts
      end
    end

    def post(opts = {})
      client.post_and_wrap href, wrapper_class, opts
    end

    def self.expand(href, opts = {})
      URITemplate.new(href).expand(opts)
    end

    protected
    attr_reader :wrapper_class, :client, :attrs

    def uri
      @uri ||= URITemplate.new(href)
    end
  end

end