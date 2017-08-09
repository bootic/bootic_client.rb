module BooticClient
  module Stubbing
    MissingStubError = Class.new(StandardError)

    module Stubber
      def stub_chain(method_path, opts = {})
        meths = method_path.split('.')
        c = 0
        opts = stringify_keys(opts)

        meths.reduce(self) do |stub, method_name|
          c += 1
          a = c == meths.size ? opts : {}
          stub.stub(method_name, a)
        end
      end

      def stub(method_name, opts = {})
        key = stub_key(method_name, opts)
        if st = stubs[key]
          st.stub(method_name, opts)
          st
        else
          stubs[key] = Stub.new(method_name, opts)
        end
      end

      def method_missing(method_name, *args, &block)
        opts = stringify_keys(args.first)
        if stub = stubs[stub_key(method_name, opts)]
          stub.returns? ? stub.returns : stub
        else
          raise MissingStubError, "No method stubbed for '#{method_name}' with options #{opts.inspect}"
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        stubs.keys.any?{|k|
          k.to_s =~ /^#{method_name.to_s}/
        }
      end

      private
      def stub_key(method_name, opts)
        [method_name.to_s, options_key(opts || {})].join('_')
      end

      def options_key(opts)
        # sort keys
        keys = opts.keys.sort
        hash = keys.each_with_object({}) do |key, h|
          value = if opts[key].is_a?(Hash)
            options_key(opts[key])
          else
            opts[key].to_s
          end

          h[key] = value
        end

        hash.inspect
      end

      def stringify_keys(hash)
        return hash unless hash.is_a?(Hash)

        hash.each_with_object({}) do |(k, v), h|
          h[k.to_s] = stringify_keys(v)
        end
      end
    end

    class StubRoot
      include Stubber

      def initialize
        @stubs = {}
      end

      private
      attr_reader :stubs
    end

    class Stub
      include Stubber

      def initialize(method_name = '', opts = {})
        @method_name, @opts = method_name, opts
        @return_data = nil
        @stubs = {}
      end

      def and_return_data(data)
        @return_data = data
        self
      end

      def returns?
        !!@return_data
      end

      def returns
        if @return_data.is_a?(Array)
          @return_data.map{|d| BooticClient::Entity.new(d, nil)}
        else
          BooticClient::Entity.new(@return_data || {}, nil)
        end
      end

      private
      attr_reader :stubs
    end
  end
end
