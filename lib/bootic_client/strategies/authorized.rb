require 'bootic_client/strategies/oauth2_strategy'

module BooticClient
  module Strategies

    class Authorized < Oauth2Strategy
      private

      def validate!
        raise ArgumentError, 'options MUST include access_token' unless options[:access_token]
        raise ArgumentError, 'must include a Configuration object' unless config
      end

      def get_token
        # The JWT grant must have an expiration date, in seconds since the epoch.
        # For most cases a few seconds should be enough.
        exp = Time.now.utc.to_i + 30

        # Use the "assertion" flow to exchange the JWT grant for an access token
        access_token = auth.assertion.get_token(
          hmac_secret: config.client_secret,
          iss: config.client_id,
          prn: client.options[:access_token],
          aud: 'api',
          exp: exp,
          scope: ''
        )

        access_token.token
      end

      def auth
        @auth ||= OAuth2::Client.new('', '', site: config.auth_host)
      end
    end

  end

  strategies[:authorized] = Strategies::Authorized
end
