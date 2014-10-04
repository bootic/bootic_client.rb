require "bootic_client/relation"
require 'ostruct'

module BooticClient
  class Entity

    CURIE_EXP = /(.+):(.+)/.freeze
    CURIES_REL = 'curies'.freeze
    SPECIAL_PROP_EXP = /^_.+/.freeze

    attr_reader :curies, :entities

    def initialize(attrs, client, top = self)
      @attrs, @client, @top = attrs, client, top
      build!
    end

    def to_hash
      @attrs
    end

    def [](key)
      properties[key.to_sym] || entities[key.to_sym]
    end

    def has?(prop_name)
      has_property?(prop_name) || has_entity?(prop_name) || has_rel?(prop_name)
    end

    def can?(rel_name)
      has_rel? rel_name
    end

    def inspect
      %(#<#{self.class.name} props: [#{properties.keys.join(', ')}] rels: [#{rels.keys.join(', ')}] entities: [#{entities.keys.join(', ')}]>)
    end

    def properties
      @properties ||= attrs.select{|k,v| !(k =~ SPECIAL_PROP_EXP)}.each_with_object({}) do |(k,v),memo|
        memo[k.to_sym] = Entity.wrap(v)
      end
    end

    def links
      @links ||= attrs.fetch('_links', {})
    end

    def self.wrap(obj)
      case obj
      when Hash
        OpenStruct.new(obj)
      when Array
        obj.map{|e| wrap(e)}
      else
        obj
      end
    end

    def method_missing(name, *args, &block)
      if !block_given?
        if has_property?(name)
          self[name]
        elsif has_entity?(name)
          entities[name]
        elsif has_rel?(name)
          rels[name].run(*args)
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
      properties.has_key? prop_name.to_sym
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

    def rels
      @rels ||= (
        links = attrs.fetch('_links', {})
        links.each_with_object({}) do |(rel,rel_attrs),memo|
          if rel =~ CURIE_EXP
            _, curie_namespace, rel = rel.split(CURIE_EXP)
            if curie = curies.find{|c| c['name'] == curie_namespace}
              rel_attrs['docs'] = Relation.expand(curie['href'], rel: rel)
            end
          end
          if rel != CURIES_REL
            rel_attrs['name'] = rel
            memo[rel.to_sym] = Relation.new(rel_attrs, client, Entity)
          end
        end
      )
    end

    protected

    attr_reader :client, :top, :attrs

    def iterable?
      has_entity?(:items) && entities[:items].respond_to?(:each)
    end

    def build!
      @curies = top.links.fetch('curies', [])

      @entities = attrs.fetch('_embedded', {}).each_with_object({}) do |(k,v),memo|
        memo[k.to_sym] = if v.kind_of?(Array)
          v.map{|ent_attrs| Entity.new(ent_attrs, client, top)}
        else
          Entity.new(v, client, top)
        end
      end
    end
  end
end
