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

    before do
      client.stub(:get_and_wrap).with('/foo/bars', BooticClient::Entity).and_return entity
    end

    it 'fetches data and returns entity' do
      relation.get.tap do |ent|
        expect(ent).to eql(entity)
      end
    end
  end
end
