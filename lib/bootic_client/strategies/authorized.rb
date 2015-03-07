require 'bootic_client/strategies/strategy'

module BooticClient
  module Strategies

    class Authorized < Strategy
      protected

      def validate!(options)
        raise "options MUST include access_token" unless options[:access_token]
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
          exp: exp
        )

        access_token.token
      end

      def auth
        @auth ||= OAuth2::Client.new(nil, nil, site: config.auth_host)
      end
    end

  end

  strategies[:authorized] = Strategies::Authorized
end
