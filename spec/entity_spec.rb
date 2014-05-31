require 'spec_helper'

describe BooticClient::Entity do
  let(:client) { double(:client) }
  let(:list_payload) do
    {
      total_items: 10,
      per_page: 2,
      _links: {
        self: {href: '/foo'},
        next: { href: '/foo?page=2'}
      },
      _embedded: {
        items: [
          {
            title: 'iPhone 4',
            price: 12345,
            _links: {
              self: {href: '/products/iphone4'}
            },
            _embedded: {
              shop: {
                name: 'Acme'
              }
            }
          },

          {
            title: 'iPhone 5',
            price: 12342,
            _links: {
              self: {href: '/products/iphone5'}
            },
            _embedded: {
              shop: {
                name: 'Apple'
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
    end

    describe 'embedded entities' do
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
    end
  end

end
