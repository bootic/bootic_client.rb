# frozen_string_literal: true

require 'hyperlinked/strategies/oauth2_strategy'

module Hyperlinked
  module Strategies

    class ClientCredentials < Oauth2Strategy
      private

      def get_token
        opts = {}
        opts['scope'] = options.delete(:scope) if options[:scope]
        token = auth.client_credentials.get_token(opts, 'auth_scheme' => 'basic')
        token.token
      end
    end

  end

  strategies[:client_credentials] = Strategies::ClientCredentials
end
