require 'logger'
require "bootic_client/version"
require "bootic_client/entity"
require "bootic_client/relation"
require "bootic_client/client"

module BooticClient
  NilConfigurationError = Class.new(StandardError)

  AUTH_HOST = 'https://auth.bootic.net'.freeze
  API_ROOT = 'https://api.bootic.net/v1'.freeze

  class << self
    attr_accessor :logging
    attr_reader :client_id, :client_secret, :cache_store

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

    def client_id=(v)
      set_non_nil :client_id, v
    end

    def client_secret=(v)
      set_non_nil :client_secret, v
    end

    def cache_store=(v)
      set_non_nil :cache_store, v
    end

    def auth_host=(v)
      set_non_nil :auth_host, v
    end

    def api_root=(v)
      set_non_nil :api_root, v
    end

    def logger=(v)
      set_non_nil :logger, v
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

    def set_non_nil(name, v)
      raise NilConfigurationError, "#{name} cannot be nil" if v.nil?
      instance_variable_set("@#{name}", v)
    end
  end
end
