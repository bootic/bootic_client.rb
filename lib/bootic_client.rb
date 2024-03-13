require 'logger'
require_relative './bootic_client/version'
require_relative './bootic_client/entity'
require_relative './bootic_client/relation'
require_relative './bootic_client/client'
require_relative './bootic_client/configuration'

module BooticClient
  class << self
    def strategies
      @strategies ||= {}
    end

    def client(strategy_name, client_opts = {}, &on_new_token)
      return @stubber if @stubber

      opts = client_opts.dup
      opts[:logging] = configuration.logging
      opts[:logger] = configuration.logger if configuration.logging
      opts[:cache_store] = configuration.cache_store if configuration.cache_store
      opts[:user_agent] = configuration.user_agent if configuration.user_agent
      require "bootic_client/strategies/#{strategy_name}"
      strategies.fetch(strategy_name.to_sym).new configuration, opts, &on_new_token
    end

    def auth_host
      @auth_host || AUTH_HOST
    end

    def configure(&block)
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def stub!
      require "bootic_client/stubbing"
      @stubber = Stubbing::StubRoot.new
    end

    def stub_chain(method_chain, opts = {})
      @stubber.stub_chain(method_chain, opts)
    end

    def unstub!
      @stubber = nil
    end
  end
end
