require 'oauth2'

module BooticClient
  module Strategies
    class Strategy

      def initialize(config, client_opts = {}, &on_new_token)
        @config, @options, @on_new_token = config, client_opts, (on_new_token || Proc.new{})
        raise "MUST include client_id" unless config.client_id
        raise "MUST include client_secret" unless config.client_secret
        raise "MUST include api_root" unless config.api_root
        validate! @options
      end

      def root
        request_and_wrap :get, config.api_root, Entity
      end

      def request_and_wrap(request_method, href, wrapper_class, payload = {})
        begin
          wrapper_class.new client.send(request_method, href, payload).body, self
        rescue TokenError => e
          new_token = get_token
          client.options[:access_token] = new_token
          on_new_token.call new_token
          wrapper_class.new client.send(request_method, href, payload).body, self
        end
      end

      def inspect
        %(#<#{self.class.name} cid: #{config.client_id} root: #{config.api_root} auth: #{config.auth_host}>)
      end

      protected

      attr_reader :config, :options, :on_new_token

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

      def client
        @client ||= Client.new(options)
      end
    end
  end
end
