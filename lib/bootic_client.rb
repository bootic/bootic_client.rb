require "bootic_client/version"
require "bootic_client/entity"
require "bootic_client/relation"
require "bootic_client/client"

module BooticClient

  AUTH_HOST = 'https://auth.bootic.net'.freeze

  class << self

    attr_accessor :client_secret, :client_id, :logger
    attr_writer :auth_host

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

    def configure(&block)
      yield self
    end
  end

end
