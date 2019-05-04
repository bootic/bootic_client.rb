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
        'age' => 22,
        'another_object' => {'foo' => 'bar'}
      },
      '_links' => {
        'self' => {'href' => '/foo'},
        'next' => { 'href' => '/foo?page=2'},
        'btc:products' => {'href' => '/all/products'},
        'btc:search' => {'href' => '/search{?q}', 'templated' => true},
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
            'published' => false,
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
            'published' => true,
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

    it 'has hash access to properties' do
      expect(entity[:total_items]).to eql(10)
    end

    it 'wraps object properties as entities' do
      expect(entity.an_object).to be_a described_class
      expect(entity.an_object.name).to eql('Foobar')
      expect(entity.an_object.age).to eql(22)
      expect(entity.an_object.another_object).to be_a described_class
      expect(entity.an_object.another_object.foo).to eq 'bar'
    end

    it 'has a #properties object' do
      expect(entity.properties[:total_items]).to eql(10)
    end

    it 'responds to #has?' do
      expect(entity.has?(:total_items)).to eql(true)
      expect(entity.has?(:items)).to eql(true)
      expect(entity.has?(:foobar)).to eql(false)
    end

    describe '#to_hash' do
      it 'returns original data' do
        expect(entity.to_hash).to eql(list_payload)
      end
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

      it 'has hash access to properties' do
        expect(entity[:total_items]).to eql(10)
      end

      it 'recursively builds embedded entities' do
        product = entity.items.first
        product.shop.tap do |shop|
          expect(shop).to be_kind_of(BooticClient::Entity)
          expect(shop.name).to eql('Acme')
        end
      end

      it 'includes FALSE values' do
        expect(entity.items.first.published).to be false
        expect(entity.items.last.published).to be true
      end
    end #/ embedded entities

    describe 'link relations' do
      it 'responds to #has? for link relations' do
        expect(entity.has?(:next)).to eql(true)
      end

      it 'responds to #can? for link relations' do
        expect(entity.can?(:next)).to eql(true)
        expect(entity.can?(:foo)).to eql(false)
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
          expect(client).to receive(:request_and_wrap).with(:get, '/foo?page=2', BooticClient::Entity, {}).and_return next_page
          entity.next.tap do |next_entity|
            expect(next_entity).to be_kind_of(BooticClient::Entity)
            expect(next_entity.page).to eql(2)
          end
        end

        it 'takes optional URI parameters' do
          expect(client).to receive(:request_and_wrap).with(:get, '/search?q=foo', BooticClient::Entity, {}).and_return next_page
          entity.search(q: 'foo').tap do |next_entity|
            expect(next_entity).to be_kind_of(BooticClient::Entity)
            expect(next_entity.page).to eql(2)
          end
        end

        it 'complains if passing undeclared link params' do
          expect {
            entity.search(foo: 'bar')
          }.to raise_error(BooticClient::InvalidURLError)
        end
      end

    end

    describe 'iterating' do
      it 'is an enumerable if it is a list' do
        prods = []
        entity.each{|pr| prods << pr}
        expect(prods).to match_array(entity.items)
        expect(entity.map{|pr| pr}).to match_array(entity.items)
        expect(entity.reduce(0){|sum,e| sum + e.price.to_i}).to eql(24687)
        expect(entity.each).to be_kind_of(Enumerator)
      end

      it 'is not treated as an array if not a list' do
        ent = BooticClient::Entity.new({'foo' => 'bar'}, client)
        expect(ent).not_to respond_to(:each)
      end
    end

    describe '#full_set' do
      let(:page_2_data) {
        {
          'total_items' => 10,
          'per_page' => 3,
          'page' => 2,
          '_links' => {
            'self' => {'href' => '/foo?page=2'},
            'next' => { 'href' => '/foo?page=3'}
          },
          "_embedded" => {
            'items' => [
              {"title" => "Item 3"},
              {"title" => "Item 4"},
              {"title" => "Item 5"}
            ]
          }
        }
      }
      let(:page_2) { BooticClient::Entity.new(page_2_data, client) }

      it 'lazily enumerates entries across pages, making as little requests as possible' do
        expect(client).to receive(:request_and_wrap).with(:get, '/foo?page=2', BooticClient::Entity, {}).and_return page_2
        expect(client).to_not receive(:request_and_wrap).with(:get, '/foo?page=3', BooticClient::Entity, {})
        results = entity.full_set.first(4)
        titles = results.map(&:title)
        expect(titles).to match_array(['iPhone 4', 'iPhone 5', 'Item 3', 'Item 4'])
      end
    end
  end

  context 'empty response' do
    it 'does not break if response is nil' do
      entity = BooticClient::Entity.new(nil, client)
      expect(entity.links).to eql({})
    end

    it 'does not break if response is empty string' do
      entity = BooticClient::Entity.new('', client)
      expect(entity.links).to eql({})
    end
  end

end
