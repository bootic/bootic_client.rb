require 'faraday'
require 'faraday_middleware'
require 'faraday-http-cache'
require "bootic_client/errors"
require 'faraday/adapter/net_http_persistent'

module BooticClient

  class Client

    USER_AGENT = "[BooticClient v#{VERSION}] Ruby-#{RUBY_VERSION} - #{RUBY_PLATFORM}".freeze
    JSON_MIME = 'application/json'.freeze

    attr_reader :options, :api_root

    def initialize(api_root, options = {}, &block)
      @api_root = api_root
      @options = {
        access_token: nil,
        logging: false
      }.merge(options.dup)

      @options[:cache_store] = @options[:cache_store] || Faraday::HttpCache::MemoryStore.new

      conn &block if block_given?
    end

    def request_and_wrap(request_method, href, wrapper_class, payload = {})
      wrapper_class.new send(request_method, href, payload).body, self
    end
 
    def get(href, query = {})
      validated! do
        conn.get do |req|
          req.url href
          req.headers.update request_headers
          req.params.update(query)
        end
      end
    end

    def post(href, payload = {})
      validated! do
        conn.post do |req|
          req.url href
          req.headers.update request_headers
          req.body = JSON.dump(payload)
        end
      end
    end

    def put(href, payload = {})
      validated! do
        conn.put do |req|
          req.url href
          req.headers.update request_headers
          req.body = JSON.dump(payload)
        end
      end
    end

    def patch(href, payload = {})
      validated! do
        conn.patch do |req|
          req.url href
          req.headers.update request_headers
          req.body = JSON.dump(payload)
        end
      end
    end

    def delete(href, query = {})
      validated! do
        conn.delete do |req|
          req.url href
          req.headers.update request_headers
        end
      end
    end

    protected

    def conn(&block)
      @conn ||= Faraday.new(url: api_root) do |f|
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
        'Authorization' => "Bearer #{options[:access_token]}",
        'User-Agent' => USER_AGENT,
        'Accept' => JSON_MIME,
        'Content-Type' => JSON_MIME
      }
    end

    def validated!(&block)
      validate_request!
      resp = yield
      raise_if_invalid! resp
      resp
    end

    def validate_request!
      raise NoAccessTokenError, "Missing access token" unless options[:access_token]
    end

    def raise_if_invalid!(resp)
      raise ServerError, "Server Error" if resp.status > 499
      raise NotFoundError, "Not Found" if resp.status == 404
      raise UnauthorizedError, "Unauthorized request" if resp.status == 401
      raise AccessForbiddenError, "Access Forbidden" if resp.status == 403
    end
  end

end
