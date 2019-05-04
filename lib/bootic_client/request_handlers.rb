require 'json'

module BooticClient
  module RequestHandlers
    class Set
      def initialize(handlers = [])
        @handlers = handlers
      end

      def resolve(response, client)
        custom = @handlers.find do |handler|
          obj = handler.call(response, client)
          break obj if obj
          nil
        end
        # if no handler found,
        # return raw Faraday response
        custom || response
      end

      def add(handler)
        @handlers << handler
      end

      def to_a
        @handlers
      end
    end

    JSON_MIME_EXP = /^application\/json/.freeze
    CONTENT_TYPE = 'Content-Type'.freeze

    Hal = Proc.new do |resp, client|
      if resp.headers[CONTENT_TYPE] =~ JSON_MIME_EXP
        data = ::JSON.parse(resp.body)
        Entity.new(data, client)
      end
    end
  end
end
