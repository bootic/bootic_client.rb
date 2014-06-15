module BooticClient
  class TransportError < StandardError; end
  class ServerError < TransportError; end
  class NotFoundError < ServerError; end
  class TokenError < ServerError; end
  class UnauthorizedError < TokenError; end
  class AccessForbiddenError < TokenError; end
  class NoAccessTokenError < TokenError; end
end