require 'logger'
require 'faraday'
require 'faraday_middleware'
require 'faraday-http-cache'
require "bootic_client/errors"
require 'faraday/adapter/net_http_persistent'

module BooticClient

  class Client

    API_URL = 'https://api.bootic.net'.freeze
    USER_AGENT = "[BooticClient v#{VERSION}] Ruby-#{RUBY_VERSION} - #{RUBY_PLATFORM}".freeze

    attr_reader :options

    def initialize(options = {}, &block)
      @options = {
        api_url: API_URL,
        access_token: nil,
        logging: false,
        logger: ::Logger.new(STDOUT)
      }.merge(options.dup)

      @options[:cache_store] = @options[:cache_store] || Faraday::HttpCache::MemoryStore.new

      conn &block if block_given?
    end

    def get_and_wrap(href, wrapper_class, query = {})
      wrapper_class.new get(href, query).body, self
    end

    def get(href, query = {})
      validate_request!

      resp = conn.get do |req|
        req.url href
        req.params.update(query)
        req.headers['Authorization'] = "Bearer #{options[:access_token]}"
        req.headers['User-Agent'] = USER_AGENT
      end

      raise_if_invalid! resp

      resp
    end

    protected

    def conn(&block)
      @conn ||= Faraday.new(url: options[:api_url]) do |f|
        cache_options = {shared_cache: false, store: options[:cache_store]}
        cache_options[:logger] = options[:logger] if options[:logging]

        f.use :http_cache, cache_options
        f.response :logger, options[:logger] if options[:logging]
        f.response :json
        yield f if block_given?
        f.adapter :net_http_persistent
      end
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