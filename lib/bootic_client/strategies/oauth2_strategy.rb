# frozen_string_literal: true

require 'oauth2'
require 'bootic_client/strategies/strategy'

module BooticClient
  module Strategies

    class Oauth2Strategy < Strategy

      def inspect
        %(#<#{self.class.name} cid: #{config.client_id} root: #{config.api_root} auth: #{config.auth_host}>)
      end

      private

      def validate!
        raise ArgumentError, 'MUST include client_id' unless config.client_id
        raise ArgumentError, 'MUST include client_secret' unless config.client_secret
        raise ArgumentError, 'MUST include api_root' unless config.api_root
      end

      def pre_flight
        update_token! unless options[:access_token]
      end

      def request_headers
        {
          'Authorization' => "Bearer #{options[:access_token]}"
        }
      end

      def retryable(&block)
        begin
          yield
        rescue AuthorizationError => e
          update_token!
          yield
        end
      end

      def update_token!
        new_token = get_token
        options[:access_token] = new_token
        on_new_token.call new_token
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

    end

  end
end
