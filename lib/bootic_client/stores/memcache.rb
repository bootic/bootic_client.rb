require 'dalli'

module BooticClient
  module Stores
    class Memcache
      attr_reader :client

      def initialize(server_hosts, dalli_options = {})
        @client = Dalli::Client.new(Array(server_hosts), dalli_options)
      end

      def read(key)
        @client.get key.to_s
      end

      def write(key, data, ttl = nil)
        @client.set key.to_s, data, ttl
      end

      def get(key)
        @client.get key
      end

      def delete(key)
        @client.delete key
      end

      def set(key, data, ttl = nil)
        @client.set key, data, ttl
      end

      def stats
        @client.stats
      end
    end
  end
end
