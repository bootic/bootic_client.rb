# frozen_string_literal: true

module BooticClient
  class TransportError < StandardError; end
  class ServerError < TransportError; end
  class NotFoundError < ServerError; end
  class AuthorizationError < ServerError; end
  class UnauthorizedError < AuthorizationError; end
  class AccessForbiddenError < AuthorizationError; end
  class ClientError < TransportError; end
  class InvalidURLError < ClientError; end
end
