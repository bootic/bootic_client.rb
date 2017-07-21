require 'spec_helper'

describe BooticClient::Relation do
  let(:client) { double(:client) }
  let(:attributes) {{'href' => '/foo/bars', 'type' => 'application/json', 'title' => 'A relation', 'name' => 'self'}}
  let(:relation) { BooticClient::Relation.new(attributes, client) }

  describe 'attributes' do
    it 'has readers for known relation attributes' do
      expect(relation.href).to eql('/foo/bars')
      expect(relation.type).to eql('application/json')
      expect(relation.title).to eql('A relation')
      expect(relation.name).to eql('self')
    end
  end

  describe '#to_hash' do
    it 'returns attributes' do
      hash = relation.to_hash
      expect(hash).to eq attributes
    end
  end

  describe '#run' do
    let(:entity) { BooticClient::Entity.new({'title' => 'Foobar'}, client) }

    describe 'running GET by default' do
      it 'fetches data and returns entity' do
        allow(client).to receive(:request_and_wrap).with(:get, '/foo/bars', BooticClient::Entity, {}).and_return entity
        expect(relation.run).to eql(entity)
      end

      context 'without URI templates' do
        let(:relation) { BooticClient::Relation.new({'href' => '/foos/bar', 'type' => 'application/json', 'title' => 'A relation'}, client) }

        it 'is not templated' do
          expect(relation.templated?).to eql(false)
        end

        it 'does not have parameters' do
          expect(relation.parameters).to eql []
        end

        it 'passes query string to client' do
          expect(client).to receive(:request_and_wrap).with(:get, '/foos/bar', BooticClient::Entity, id: 2, q: 'test', page: 2).and_return entity
          expect(relation.run(id: 2, q: 'test', page: 2)).to eql(entity)
        end
      end

      context 'with URI templates' do
        let(:relation) { BooticClient::Relation.new({'href' => '/foos/{id}{?q,page}', 'type' => 'application/json', 'title' => 'A relation', 'templated' => true}, client) }

        it 'is templated' do
          expect(relation.templated?).to eql(true)
        end

        it 'complains if missing path variables' do
          expect{
            relation.run
          }.to raise_error BooticClient::InvalidURLError
        end

        it 'works with defaults' do
          expect(client).to receive(:request_and_wrap).with(:get, '/foos/123', BooticClient::Entity, {}).and_return entity
          expect(relation.run(id: 123)).to eql(entity)
        end

        it 'has parameter list' do
          expect(relation.parameters).to eql ['id', 'q', 'page']
        end

        it 'interpolates tokens' do
          expect(client).to receive(:request_and_wrap).with(:get, '/foos/2?q=test&page=2', BooticClient::Entity, {}).and_return entity
          expect(relation.run(id: 2, q: 'test', page: 2)).to eql(entity)
        end

        it 'complains if passing undeclared query variables' do
          expect{
            relation.run(id: 2, q: 'test', page: 2, other: 'foo')
          }.to raise_error BooticClient::InvalidURLError
        end
      end

      context "configured to not complain on undeclared variables" do
        let(:relation) {
          BooticClient::Relation.new({
            'href' => '/foos/{id}{?q,page}',
            'templated' => true
            },
            client,
            BooticClient::Entity,
            complain_on_undeclared_params: false
          )
        }

        it "whitelists params but does not complain" do
          expect(client).to receive(:request_and_wrap).with(:get, '/foos/2?q=test&page=3', BooticClient::Entity, {foo: 1}).and_return entity

          relation.run(id: 2, q: 'test', page: 3, foo: 1)
        end
      end
    end

    describe 'POST' do
      let(:relation) { BooticClient::Relation.new({'href' => '/foo/bars', 'type' => 'application/json', 'name' => 'self', 'method' => 'post'}, client) }
      let(:relation_templated) { BooticClient::Relation.new({'href' => '/foo/{bars}', 'templated' => true, 'type' => 'application/json', 'name' => 'self', 'method' => 'post'}, client) }

      it 'POSTS data and returns resulting entity' do
        allow(client).to receive(:request_and_wrap).with(:post, '/foo/bars', BooticClient::Entity, {}).and_return entity
        expect(relation.run).to eql(entity)
      end

      it 'interpolates templated URLs and sends remaining as BODY' do
        allow(client).to receive(:request_and_wrap).with(:post, '/foo/123', BooticClient::Entity, {foo: 'bar'}).and_return entity
        expect(relation_templated.run(bars: 123, foo: 'bar')).to eql(entity)
      end
    end

    describe 'DELETE' do
      let(:relation) { BooticClient::Relation.new({'href' => '/foo/bars', 'type' => 'application/json', 'name' => 'self', 'method' => 'delete'}, client) }

      it 'DELETEs data and returns resulting entity' do
        allow(client).to receive(:request_and_wrap).with(:delete, '/foo/bars', BooticClient::Entity, {}).and_return entity
        expect(relation.run).to eql(entity)
      end
    end
  end
end
