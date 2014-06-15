require 'logger'
require "bootic_client/version"
require "bootic_client/entity"
require "bootic_client/relation"
require "bootic_client/client"

module BooticClient

  AUTH_HOST = 'https://auth.bootic.net'.freeze
  API_ROOT = 'https://api.bootic.net/v1'.freeze

  class << self

    attr_accessor :client_secret, :client_id, :logging, :cache_store
    attr_writer :auth_host, :api_root, :logger

    def strategies
      @strategies ||= {}
    end

    def client(strategy_name, client_opts = {}, &on_new_token)
      opts = client_opts.dup
      opts[:logging] = logging
      opts[:logger] = logger if logging
      opts[:cache_store] = cache_store if cache_store
      require "bootic_client/strategies/#{strategy_name}"
      strategies.fetch(strategy_name.to_sym).new self, opts, &on_new_token
    end

    def auth_host
      @auth_host || AUTH_HOST
    end

    def api_root
      @api_root || API_ROOT
    end

    def logger
      @logger || ::Logger.new(STDOUT)
    end

    def configure(&block)
      yield self
    end
  end

end
