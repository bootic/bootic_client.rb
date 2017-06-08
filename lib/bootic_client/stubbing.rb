module BooticClient
  module Stubbing
    MissingStubError = Class.new(StandardError)

    module Stubber
      def stub_chain(method_path, opts = {})
        meths = method_path.split('.')
        c = 0
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
        opts = args.first
        if stub = stubs[stub_key(method_name, opts)]
          stub.returns? ? stub.returns : stub
        else
          raise MissingStubError, "No method stubbed for '#{method_name}' with options #{opts.inspect}"
        end
      end

      private
      def stub_key(method_name, opts)
        [method_name.to_s, options_key(opts || {})].join('_')
      end

      def options_key(value)
        value.inspect
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
        BooticClient::Entity.new(@return_data || {}, nil)
      end

      private
      attr_reader :stubs
    end
  end
end
