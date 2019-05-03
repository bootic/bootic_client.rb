module BooticClient
  module Strategies
    class Strategy

      attr_reader :options

      def initialize(config, client_opts = {}, &on_new_token)
        @config, @options, @on_new_token = config, client_opts, (on_new_token || Proc.new{})
        validate!
      end

      def root
        request_and_wrap :get, config.api_root
      end

      def from_hash(hash, wrapper_class = Entity)
        wrapper_class.new hash, self
      end

      def from_url(url)
        request_and_wrap :get, url
      end

      def request_and_wrap(request_method, href, payload = {})
        pre_flight
        retryable do
          resp = client.send(request_method, href, payload, request_headers)
          BooticClient::Entity.new(resp.body, self)
          # wrapper_class.new(resp.body, self)
        end
      end

      def inspect
        %(#<#{self.class.name} root: #{config.api_root}>)
      end

      protected

      attr_reader :config, :on_new_token

      def validate!
        # Overwrite in sub classes
        # to raise ArgumentErrors on
        # missing config attributes of options values.
      end

      def pre_flight
        # Runs before every request
        # Overwrite in sub classes to run checks
        # (ie authorisation status, missing options, expired token refresh)
      end

      # Noop.
      # Overwrite in sub classes to implement retryable requests.
      # Example:
      #
      #   def retryable(&block)
      #      begin
      #        yield # issue request
      #      rescue SomeException => e
      #        fix_cause_of_exception
      #        yield # try again
      #      end
      #   end
      #
      def retryable(&block)
        yield
      end

      # Noop. Merge these headers into every request.
      def request_headers
        {}
      end

      def client
        @client ||= Client.new(options)
      end
    end
  end
end
