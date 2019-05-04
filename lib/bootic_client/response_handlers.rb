require 'json'

module BooticClient
  module ResponseHandlers
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

      def append(handler)
        @handlers << handler
      end

      def prepend(handler)
        @handlers.unshift handler
      end

      def to_a
        @handlers
      end
    end

    JSON_MIME_EXP = /^application\/json/.freeze
    IMAGE_MIME_EXP = /^image\//.freeze
    CONTENT_TYPE = 'Content-Type'.freeze
    IO = Struct.new(:io, :file_name, :mime_type) do
      def read
        io.read
      end
    end

    Hal = Proc.new do |resp, client|
      if resp.headers[CONTENT_TYPE] =~ JSON_MIME_EXP
        data = ::JSON.parse(resp.body)
        Entity.new(data, client)
      end
    end

    File = Proc.new do |resp, client|
      if resp.headers[CONTENT_TYPE] =~ IMAGE_MIME_EXP
        fname = ::File.basename(resp.env[:url].to_s)
        IO.new(
          StringIO.new(resp.body),
          fname,
          resp.headers[CONTENT_TYPE]
        )
      end
    end
  end
end
