# frozen_string_literal: true

require 'bootic_client/strategies/strategy'

module BooticClient
  module Strategies
    class BasicAuth < Strategy

      def inspect
        %(#<#{self.class.name} root: #{config.api_root} username: #{options[:username]}>)
      end

      private

      def validate!
        raise ArgumentError, 'options MUST include username' unless options[:username]
        raise ArgumentError, 'options MUST include password' unless options[:password]
      end

      def client
        @client ||= Client.new(options) do |c|
          c.request :authorization, :basic, options[:username], options[:password]
        end
      end
    end
  end

  strategies[:basic_auth] = Strategies::BasicAuth
end
