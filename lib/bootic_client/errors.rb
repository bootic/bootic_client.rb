module BooticClient
  class TransportError < StandardError; end
  class ServerError < TransportError; end
  class NotFoundError < ServerError; end
  class UnauthorizedError < ServerError; end
  class AccessForbiddenError < ServerError; end
end