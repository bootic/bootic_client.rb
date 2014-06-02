require 'spec_helper'

describe BooticClient::Entity do
  let(:client) { double(:client) }
  let(:list_payload) do
    {
      'total_items' => 10,
      'per_page' => 2,
      'page' => 1,
      'an_object' => {
        'name' => 'Foobar',
        'age' => 22
      },
      '_links' => {
        'self' => {'href' => '/foo'},
        'next' => { 'href' => '/foo?page=2'},
        'btc:products' => {'href' => '/all/products'},
        'btc:search' => {'href' => '/search{?q}'},
        'curies' => [
          {
            'name' => "btc",
            'href' => "https://developers.bootic.net/rels/{rel}",
            'templated' => true
          }
        ]
      },
      "_embedded" => {
        'items' => [
          {
            'title' => 'iPhone 4',
            'price' => 12345,
            '_links' => {
              'self' => {href: '/products/iphone4'},
              'btc:delete_product' => {'href' => '/products/12345'}
            },
            '_embedded' => {
              'shop' => {
                'name' => 'Acme'
              }
            }
          },

          {
            'title' => 'iPhone 5',
            'price' => 12342,
            '_links' => {
              'self' => {href: '/products/iphone5'}
            },
            '_embedded' => {
              'shop' => {
                'name' => 'Apple'
              }
            }
          }
          
        ] # / items
      }
    }
  end

  context 'parsing JSON HAL' do
    let(:entity) { BooticClient::Entity.new(list_payload, client) }

    it 'knows about plain properties' do
      expect(entity.total_items).to eql(10)
      expect(entity.per_page).to eql(2)
      expect(entity.page).to eql(1)
    end

    it 'wraps object properties as entities' do
      expect(entity.an_object.name).to eql('Foobar')
      expect(entity.an_object.age).to eql(22)
    end

    it 'has a #properties object' do
      expect(entity.properties[:total_items]).to eql(10)
    end

    it 'responds to #has?' do
      expect(entity.has?(:total_items)).to eql(true)
      expect(entity.has?(:items)).to eql(true)
      expect(entity.has?(:foobar)).to be_false
    end

    describe 'embedded entities' do

      it 'has a #entities object' do
        expect(entity.entities[:items]).to be_a(Array)
        expect(entity.entities[:items].first.entities[:shop]).to be_kind_of(BooticClient::Entity)
      end

      it 'are exposed like normal attributes' do
        expect(entity.items).to be_kind_of(Array)
        entity.items.first.tap do |product|
          expect(product).to be_kind_of(BooticClient::Entity)
          expect(product.title).to eql('iPhone 4')
        end
      end

      it 'recursively builds embedded entities' do
        product = entity.items.first
        product.shop.tap do |shop|
          expect(shop).to be_kind_of(BooticClient::Entity)
          expect(shop.name).to eql('Acme')
        end
      end
    end #/ embedded entities

    describe 'link relations' do
      it 'responds to #has? for link relations' do
        expect(entity.has?(:next)).to eql(true)
      end

      it 'builds relation objects' do
        expect(entity.rels[:next]).to be_kind_of(BooticClient::Relation)
        expect(entity.rels[:next].href).to eql('/foo?page=2')
      end

      it 'understands namespaced cURIes' do
        expect(entity.rels[:products]).to be_kind_of(BooticClient::Relation)
        expect(entity.rels[:products].href).to eql('/all/products')
      end

      it 'adds docs if cURIes available' do
        expect(entity.rels[:products].docs).to eql('https://developers.bootic.net/rels/products')
      end

      it 'adds docs if cURIes available even in nested entities' do
        prod = entity.items.first
        expect(prod.rels[:delete_product].docs).to eql('https://developers.bootic.net/rels/delete_product')
      end

      context 'eagerly fetching rels' do
        let(:next_page) { BooticClient::Entity.new({'page' => 2}, client) }

        it 'exposes link target resources as normal properties' do
          expect(client).to receive(:get_and_wrap).with('/foo?page=2', BooticClient::Entity).and_return next_page
          entity.next.tap do |next_entity|
            expect(next_entity).to be_kind_of(BooticClient::Entity)
            expect(next_entity.page).to eql(2)
          end
        end

        it 'takes optional URI parameters' do
          expect(client).to receive(:get_and_wrap).with('/search?q=foo', BooticClient::Entity).and_return next_page
          entity.search(q: 'foo').tap do |next_entity|
            expect(next_entity).to be_kind_of(BooticClient::Entity)
            expect(next_entity.page).to eql(2)
          end
        end
      end

    end

    describe 'iterating' do
      it 'iterates items if it is a list' do
        prods = []
        entity.each{|pr| prods << pr}
        expect(prods).to match_array(entity.items)
      end

      it 'iterates itself if not a list' do
        ent = BooticClient::Entity.new({'foo' => 'bar'}, client)
        ents = []
        ent.each{|e| ents << e}
        expect(ents).to match_array([ent])
      end
    end
  end

end
