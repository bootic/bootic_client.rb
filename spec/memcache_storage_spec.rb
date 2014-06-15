require 'spec_helper'
require 'bootic_client/stores/memcache'

describe BooticClient::Stores::Memcache do
  let(:dalli) { double('Dalli') }
  let(:store) { BooticClient::Stores::Memcache.new(['localhost:1112'], foo: 'bar') }

  before do
    Dalli::Client.stub(:new).with(['localhost:1112'], foo: 'bar').and_return dalli
  end

  shared_examples_for 'dalli :get' do |method_name|
    it 'delegates to Dalli client #get' do
      expect(dalli).to receive(:get).with('foo').and_return 'bar'
      expect(store.send(method_name, 'foo')).to eql('bar')
    end
  end

  shared_examples_for 'dalli :set' do |method_name|
    it 'delegates to Dalli client #set' do
      expect(dalli).to receive(:set).with('foo', 'bar', 123).and_return 'bar'
      expect(store.send(method_name, 'foo', 'bar', 123)).to eql('bar')
    end
  end

  describe '#initialize' do
    it 'creates a Dalli instance' do
      expect(Dalli::Client).to receive(:new).with(['localhost:1112'], foo: 'bar').and_return dalli
      expect(store.client).to eql(dalli)
    end
  end

  describe '#read' do
    it_behaves_like 'dalli :get', :read
  end

  describe '#get' do
    it_behaves_like 'dalli :get', :get
  end

  describe '#write' do
    it_behaves_like 'dalli :set', :write
  end

  describe '#set' do
    it_behaves_like 'dalli :set', :set
  end

  describe '#stats' do
    it 'delegates to Dalli client #stats' do
      expect(dalli).to receive(:stats).and_return 'foobar'
      expect(store.stats).to eql('foobar')
    end
  end
end