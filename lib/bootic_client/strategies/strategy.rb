require 'oauth2'

module BooticClient
  module Strategies
    class Strategy

      attr_reader :options

      def initialize(config, client_opts = {}, &on_new_token)
        @config, @options, @on_new_token = config, client_opts, (on_new_token || Proc.new{})
        raise "MUST include client_id" unless config.client_id
        raise "MUST include client_secret" unless config.client_secret
        raise "MUST include api_root" unless config.api_root
        validate! @options
        reset!
      end

      def root
        request_and_wrap :get, config.api_root, Entity
      end

      def from_hash(hash, wrapper_class = Entity)
        wrapper_class.new hash, self
      end

      def request_and_wrap(request_method, href, wrapper_class, payload = {})
        begin
          wrapper_class.new client.send(request_method, href, payload).body, self
        rescue TokenError => e
          new_token = get_token
          options[:access_token] = new_token
          reset!
          on_new_token.call new_token
          wrapper_class.new client.send(request_method, href, payload).body, self
        end
      end

      def inspect
        %(#<#{self.class.name} cid: #{config.client_id} root: #{config.api_root} auth: #{config.auth_host}>)
      end

      protected

      attr_reader :config, :on_new_token, :client

      def validate!(options)
        
      end

      def get_token
        raise "Implement this in subclasses"
      end

      def auth
        @auth ||= OAuth2::Client.new(
          config.client_id,
          config.client_secret,
          site: config.auth_host
        )
      end

      def reset!
        @client = Client.new(options)
      end
    end
  end
end
