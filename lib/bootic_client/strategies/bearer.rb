# frozen_string_literal: true

require 'bootic_client/strategies/strategy'

module BooticClient
  module Strategies
    class Bearer < Strategy

      private

      def validate!
        raise ArgumentError, 'options MUST include access_token' unless options[:access_token]
      end

      def request_headers
        {
          'Authorization' => "Bearer #{options[:access_token]}"
        }
      end
    end
  end

  strategies[:bearer] = Strategies::Bearer
end
