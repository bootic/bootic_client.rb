require "bootic_client/relation"
require 'ostruct'

module BooticClient
  module EnumerableEntity
    include Enumerable

    def each(&block)
      self[:items].each &block
    end

    def full_set
      page = self

      Enumerator.new do |yielder|
        loop do
          page.each{|item| yielder.yield item }
          raise StopIteration unless page.has_rel?(:next)
          page = page.next
        end
      end
    end
  end

  class EntityData

    CURIE_EXP = /(.+):(.+)/.freeze
    CURIES_REL = 'curies'.freeze
    SPECIAL_PROP_EXP = /^_.+/.freeze

    attr_reader :curies, :entities

    def initialize(attrs, client, top)
      @attrs, @client, @top = attrs, client, top
    end

    def to_hash
      @attrs
    end

    def properties
      @properties ||= attrs.select{|k,v| !(k =~ SPECIAL_PROP_EXP)}.each_with_object({}) do |(k,v),memo|
        memo[k.to_sym] = Entity.wrap(v)
      end
    end

    def links
      @links ||= attrs.fetch('_links', {})
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

    def build!
      @curies = top._data.links.fetch('curies', [])

      @entities = attrs.fetch('_embedded', {}).each_with_object({}) do |(k,v),memo|
        memo[k.to_sym] = if v.kind_of?(Array)
          v.map{|ent_attrs| Entity.new(ent_attrs, client, top)}
        else
          Entity.new(v, client, top)
        end
      end
    end

    private

    attr_reader :client, :top, :attrs

  end

  class Entity

    attr_reader :_data

    def initialize(attrs, client, top = self)
      @_data = EntityData.new(attrs, client, top)
      @_data.build!
      self.extend EnumerableEntity if iterable?
    end

    def [](key)
      key = key.to_sym
      has_property?(key) ? self._data.properties[key] : self._data.entities[key]
    end

    def has?(prop_name)
      has_property?(prop_name) || has_entity?(prop_name) || has_rel?(prop_name)
    end

    def can?(rel_name)
      has_rel? rel_name
    end

    def inspect
      %(#<#{self.class.name} props: [#{self._data.properties.keys.join(', ')}] rels: [#{self._data.rels.keys.join(', ')}] entities: [#{self._data.entities.keys.join(', ')}]>)
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
          self._data.entities[name]
        elsif has_rel?(name)
          self._data.rels[name].run(*args)
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
      self._data.properties.has_key? prop_name.to_sym
    end

    def has_entity?(prop_name)
      self._data.entities.has_key? prop_name.to_sym
    end

    def has_rel?(prop_name)
      self._data.rels.has_key? prop_name.to_sym
    end

    protected

    def iterable?
      has_entity?(:items) && self._data.entities[:items].respond_to?(:each)
    end

  end
end
