require "bootic_client/version"
require "bootic_client/entity"
require "bootic_client/relation"
require "bootic_client/client"

module BooticClient

  AUTH_HOST = 'https://auth.bootic.net'.freeze
  API_ROOT = 'https://api.bootic.net/v1'.freeze

  class << self

    attr_accessor :client_secret, :client_id, :logger
    attr_writer :auth_host, :api_root

    def strategies
      @strategies ||= {}
    end

    def client(strategy_name, client_opts = {}, &on_new_token)
      require "bootic_client/strategies/#{strategy_name}"
      strategies.fetch(strategy_name.to_sym).new self, client_opts, &on_new_token
    end

    def auth_host
      @auth_host || AUTH_HOST
    end

    def api_root
      @api_root || API_ROOT
    end

    def configure(&block)
      yield self
    end
  end

end
