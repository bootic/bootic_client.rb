require 'base64'
require 'faraday'
require 'faraday_middleware'
require 'faraday-http-cache'
require "bootic_client/errors"
require 'faraday/adapter/net_http_persistent'

module BooticClient

  class Client

    USER_AGENT = "[BooticClient v#{VERSION}] Ruby-#{RUBY_VERSION} - #{RUBY_PLATFORM}".freeze
    JSON_MIME = 'application/json'.freeze

    attr_reader :options

    def initialize(options = {}, &block)
      @options = {
        logging: false
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

    protected

    def conn(&block)
      @conn ||= Faraday.new do |f|
        cache_options = {shared_cache: false, store: options[:cache_store]}
        cache_options[:logger] = options[:logger] if options[:logging]

        f.use :http_cache, cache_options
        f.response :logger, options[:logger] if options[:logging]
        f.response :json
        yield f if block_given?
        f.adapter :net_http_persistent
      end
    end

    def request_headers
      {
        'User-Agent' => USER_AGENT,
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

      raise_if_invalid! resp
      resp
    end

    def raise_if_invalid!(resp)
      raise ServerError, "Server Error" if resp.status > 499
      raise NotFoundError, "Not Found" if resp.status == 404
      raise UnauthorizedError, "Unauthorized request" if resp.status == 401
      raise AccessForbiddenError, "Access Forbidden" if resp.status == 403
    end

    def sanitized(payload)
      return payload unless payload.kind_of?(Hash)
      payload.each_with_object({}) do |(k, v), memo|
        v = case v
        when IO
          Base64.encode64 v.read
        when Hash
          sanitized v
        else
          v
        end

        memo[k] = v
      end
    end
  end

end
