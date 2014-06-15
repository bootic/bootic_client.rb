require 'bootic_client/strategies/strategy'

module BooticClient
  module Strategies

    class ClientCredentials < Strategy
      protected
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