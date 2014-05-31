require "bootic_client/entity"

module BooticClient

  class Relation

    def initialize(attrs, client, wrapper_class = Entity)
      @attrs, @client, @wrapper_class = attrs, client, wrapper_class
    end

    def href
      attrs[:href]
    end

    def title
      attrs[:title]
    end

    def type
      attrs[:type]
    end

    def get
      client.get_and_wrap href, wrapper_class
    end

    protected
    attr_reader :wrapper_class, :client, :attrs
  end

end