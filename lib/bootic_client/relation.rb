# frozen_string_literal: true

require "bootic_client/whiny_uri"
require "bootic_client/entity"
require 'ostruct'

module BooticClient

  class Relation
    GET = 'get'.freeze
    HEAD = 'head'.freeze
    OPTIONS = 'options'.freeze

    class << self
      attr_writer :complain_on_undeclared_params

      def complain_on_undeclared_params
        return true unless instance_variable_defined?('@complain_on_undeclared_params')
        @complain_on_undeclared_params
      end
    end

    def initialize(attrs, client, complain_on_undeclared_params: self.class.complain_on_undeclared_params)
      @attrs, @client = attrs, client
      @complain_on_undeclared_params = complain_on_undeclared_params
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

    def parameters
      @parameters ||= templated? ? uri.variables : []
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

    def to_hash
      attrs
    end

    def transport_method
      @transport_method ||= attrs.key?('method') ? attrs['method'].to_s.downcase : GET
    end

    def run(opts = {})
      if templated?
        uri_vars = uri.variables
        payload = opts.each_with_object({}) do |(k,v),memo|
          memo[k] = v unless uri_vars.include?(k.to_s)
        end
        # remove payload vars from URI opts if destructive action
        opts = opts.reject{|k, v| !uri_vars.include?(k.to_s) } if destructive?
        client.request_and_wrap transport_method.to_sym, uri.expand(opts), payload
      else
        client.request_and_wrap transport_method.to_sym, href, opts
      end
    end

    def self.expand(href, opts = {})
      WhinyURI.new(href).expand(opts)
    end

    protected
    attr_reader :client, :attrs, :complain_on_undeclared_params

    def uri
      @uri ||= WhinyURI.new(href, complain_on_undeclared_params)
    end

    def destructive?
      ![GET, OPTIONS, HEAD].include? transport_method
    end
  end
end
