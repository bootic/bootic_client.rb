# frozen_string_literal: true

require 'hyperlinked/strategies/strategy'

module Hyperlinked
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
