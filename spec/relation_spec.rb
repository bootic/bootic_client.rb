require 'spec_helper'

describe BooticClient::Relation do
  let(:client) { double(:client) }
  let(:relation) { BooticClient::Relation.new({href: '/foo/bars', type: 'application/json', title: 'A relation'}, client) }

  describe 'attributes' do
    it 'has readers for known relation attributes' do
      expect(relation.href).to eql('/foo/bars')
      expect(relation.type).to eql('application/json')
      expect(relation.title).to eql('A relation')
    end
  end

  describe '#get' do
    let(:entity) { BooticClient::Entity.new({title: 'Foobar'}, client) }

    it 'fetches data and returns entity' do
      client.stub(:get_and_wrap).with('/foo/bars', BooticClient::Entity).and_return entity
      expect(relation.get).to eql(entity)
    end

    context 'with URI templates' do
      let(:relation) { BooticClient::Relation.new({href: '/foos/{id}{?q,page}', type: 'application/json', title: 'A relation'}, client) }

      it 'works with defaults' do
        expect(client).to receive(:get_and_wrap).with('/foos/', BooticClient::Entity).and_return entity
        expect(relation.get).to eql(entity)
      end

      it 'interpolates tokens' do
        expect(client).to receive(:get_and_wrap).with('/foos/2?q=test&page=2', BooticClient::Entity).and_return entity
        expect(relation.get(id: 2, q: 'test', page: 2)).to eql(entity)
      end
    end
  end
end
