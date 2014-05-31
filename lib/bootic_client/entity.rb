require "bootic_client/relation"

module BooticClient
  class Entity

    def initialize(attrs, client)
      @attrs, @client = attrs, client
      build!
    end

    def [](key)
      attrs[key.to_s]
    end

    def has?(prop_name)
      has_property?(prop_name) || has_entity?(prop_name) || has_rel?(prop_name)
    end

    def method_missing(name, *args, &block)
      if !block_given?
        if has_property?(name)
          self[name]
        elsif has_entity?(name)
          entities[name]
        elsif has_rel?(name)
          rels[name].get
        else
          super
        end
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      has?(method_name)
    end

    def has_property?(prop_name)
      attrs.has_key?(prop_name.to_s)
    end

    def has_entity?(prop_name)
      entities.has_key? prop_name.to_sym
    end

    def has_rel?(prop_name)
      rels.has_key? prop_name.to_sym
    end

    def each(&block)
      iterable? ? entities[:items].each(&block) : [self].each(&block)
    end

    CURIE_EXP = /(.+):(.+)/.freeze

    def rels
      @rels ||= attrs.fetch('_links', {}).each_with_object({}) do |(rel,rel_attrs),memo|
        if rel =~ CURIE_EXP
          _, curie_namespace, rel = rel.split(CURIE_EXP)
        end
        memo[rel.to_sym] = BooticClient::Relation.new(rel_attrs, client, Entity)
      end
    end

    protected

    attr_reader :attrs, :client, :entities

    def iterable?
      has_entity?(:items) && entities[:items].respond_to?(:each)
    end

    def build!
      @entities = attrs.fetch('_embedded', {}).each_with_object({}) do |(k,v),memo|
        memo[k.to_sym] = if v.kind_of?(Array)
          v.map{|ent_attrs| Entity.new(ent_attrs, client)}
        else
          Entity.new(v, client)
        end
      end
    end
  end
end