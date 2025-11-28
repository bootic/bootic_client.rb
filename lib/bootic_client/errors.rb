# frozen_string_literal: true

module BooticClient
  class TransportError < StandardError
    attr_reader :url
    def initialize(msg = nil, url = nil)
      super(msg)
      @url = url
    end
  end

  class ServerError < TransportError; end
  class NotFoundError < ServerError; end
  class AuthorizationError < ServerError; end
  class UnauthorizedError < AuthorizationError; end
  class AccessForbiddenError < AuthorizationError; end
  class ClientError < TransportError; end
  class InvalidURLError < ClientError; end
end
