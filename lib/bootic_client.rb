require 'logger'
require "bootic_client/version"
require "bootic_client/entity"
require "bootic_client/relation"
require "bootic_client/client"
require "bootic_client/configuration"

module BooticClient
  class << self
    def strategies
      @strategies ||= {}
    end

    def client(strategy_name, client_opts = {}, &on_new_token)
      opts = client_opts.dup
      opts[:logging] = configuration.logging
      opts[:logger] = configuration.logger if configuration.logging
      opts[:cache_store] = configuration.cache_store if configuration.cache_store
      opts[:user_agent] = configuration.user_agent if configuration.user_agent
      require "bootic_client/strategies/#{strategy_name}"
      strategies.fetch(strategy_name.to_sym).new configuration, opts, &on_new_token
    end

    def configure(&block)
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end
  end
end
