require 'uri_template'
require "bootic_client/entity"

module BooticClient

  class Relation

    def initialize(attrs, client, wrapper_class = Entity)
      @attrs, @client, @wrapper_class = attrs, client, wrapper_class
    end

    def href
      attrs['href']
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

    def get(opts = {})
      client.get_and_wrap uri.expand(opts), wrapper_class
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