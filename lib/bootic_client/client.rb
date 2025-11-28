# frozen_string_literal: true

require 'base64'
require 'faraday'
require 'faraday-http-cache'
require "bootic_client/errors"
require 'faraday/net_http_persistent'

module BooticClient

  class Client

    USER_AGENT = "[BooticClient v#{VERSION}] Ruby-#{RUBY_VERSION} - #{RUBY_PLATFORM}".freeze
    JSON_MIME = 'application/json'.freeze

    attr_reader :options

    def initialize(options = {}, &block)
      @options = {
        logging: false,
        faraday_adapter: [:net_http_persistent],
        user_agent: USER_AGENT
      }.merge(options.dup)

      @options[:cache_store] = @options[:cache_store] || Faraday::HttpCache::MemoryStore.new

      conn &block if block_given?
    end

    def get(href, query = {}, headers = {})
      validated_request!(:get, href) do |req|
        req.headers.update headers
        req.params.update(query)
      end
    end

    def post(href, payload = {}, headers = {})
      validated_request!(:post, href) do |req|
        req.headers.update headers
        req.body = JSON.dump(sanitized(payload))
      end
    end

    def put(href, payload = {}, headers = {})
      validated_request!(:put, href) do |req|
        req.headers.update headers
        req.body = JSON.dump(sanitized(payload))
      end
    end

    def patch(href, payload = {}, headers = {})
      validated_request!(:patch, href) do |req|
        req.headers.update headers
        req.body = JSON.dump(sanitized(payload))
      end
    end

    def delete(href, _ = {}, headers = {})
      validated_request!(:delete, href) do |req|
        req.headers.update headers
      end
    end

    class SafeCacheSerializer
      PREFIX = '__booticclient__base64__:'.freeze
      PREFIX_EXP = %r{^#{PREFIX}}.freeze

      def self.dump(data)
        data[:body] = "#{PREFIX}#{Base64.strict_encode64(data[:body])}" if data[:body].is_a?(String)
        JSON.dump(data)
      end

      def self.load(string)
        data = JSON.load(string)
        if data['body'] =~ PREFIX_EXP
          data['body'] = Base64.strict_decode64(data['body'].sub(PREFIX, ''))
        end
        data
      end
    end

    private

    def conn(&block)
      @conn ||= Faraday.new do |f|
        cache_options = {serializer: SafeCacheSerializer, shared_cache: false, store: options[:cache_store]}
        cache_options[:logger] = options[:logger] if options[:logging]

        f.use :http_cache, **cache_options
        f.response :logger, options[:logger] if options[:logging]
        yield f if block_given?
        f.adapter *Array(options[:faraday_adapter])
      end
    end

    def request_headers
      {
        'User-Agent' => options[:user_agent],
        'Accept' => JSON_MIME,
        'Content-Type' => JSON_MIME
      }
    end

    def validated_request!(verb, href, &block)
      resp = conn.send(verb) do |req|
        req.url href
        req.headers.update request_headers
        yield req if block_given?
      end

      raise_if_invalid! resp, "#{verb} #{href}"
      resp
    end

    def raise_if_invalid!(resp, url = nil)
      raise ServerError.new("Server Error", url) if resp.status > 499
      raise NotFoundError.new("Not Found", url) if resp.status == 404
      raise UnauthorizedError.new("Unauthorized Request", url) if resp.status == 401
      raise AccessForbiddenError.new("Access Forbidden", url) if resp.status == 403
    end

    def sanitized(payload)
      return payload unless payload.kind_of?(Hash)
      payload.each_with_object({}) do |(k, v), memo|
        memo[k] = if v.kind_of?(Hash)
          sanitized v
        elsif v.respond_to?(:read)
          Base64.encode64 v.read
        else
          v
        end
      end
    end
  end

end
