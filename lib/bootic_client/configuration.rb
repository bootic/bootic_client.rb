# frozen_string_literal: true

require 'bootic_client/response_handlers'

module BooticClient
  InvalidConfigurationError = Class.new(StandardError)
  VERY_BASIC_URL_CHECK = /^(http|https):/.freeze

  AUTH_HOST = 'https://auth.bootic.net'.freeze
  API_ROOT = 'https://api.bootic.net/v1'.freeze

  class Configuration
    attr_accessor :logging
    attr_reader :client_id, :client_secret, :cache_store, :user_agent

    def user_agent=(v)
      set_non_nil :user_agent, v
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
      check_url! :auth_host, v
      set_non_nil :auth_host, v
    end

    def api_root=(v)
      check_url! :api_root, v
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

    def response_handlers
      @response_handlers ||= ResponseHandlers::Set.new([
        ResponseHandlers::Hal,
        ResponseHandlers::File
      ])
    end

    private

    def set_non_nil(name, v)
      raise InvalidConfigurationError, "#{name} cannot be nil" if v.nil?
      instance_variable_set("@#{name}", v)
    end

    def check_url!(name, v)
      raise InvalidConfigurationError, "#{name} must be a valid URL" unless v.to_s =~ VERY_BASIC_URL_CHECK
    end
  end
end
