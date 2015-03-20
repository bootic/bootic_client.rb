module BooticClient
  module Strategies
    class Strategy

      attr_reader :options

      def initialize(config, client_opts = {}, &on_new_token)
        @config, @options, @on_new_token = config, client_opts, (on_new_token || Proc.new{})
        validate!
      end

      def root
        request_and_wrap :get, config.api_root, Entity
      end

      def from_hash(hash, wrapper_class = Entity)
        wrapper_class.new hash, self
      end

      def request_and_wrap(request_method, href, wrapper_class, payload = {})
        pre_flight
        retryable do
          wrapper_class.new client.send(request_method, href, payload, request_headers).body, self
        end
      end

      def inspect
        %(#<#{self.class.name} root: #{config.api_root}>)
      end

      protected

      attr_reader :config, :on_new_token

      def validate!

      end

      def pre_flight

      end

      def retryable(&block)
        yield
      end

      def request_headers
        {}
      end

      def client
        @client ||= Client.new(options)
      end
    end
  end
end
