require 'spec_helper'

describe BooticClient::Client::BoundedMemoryStore do
  subject(:store) { described_class.new(max_size: 3) }

  describe '#write and #read' do
    it 'stores and retrieves values' do
      store.write('a', 'alpha')
      expect(store.read('a')).to eq 'alpha'
    end

    it 'returns nil for missing keys' do
      expect(store.read('missing')).to be_nil
    end
  end

  describe '#exist?' do
    it 'returns true for a stored key' do
      store.write('a', 'alpha')
      expect(store.exist?('a')).to be true
    end

    it 'returns false for an absent key' do
      expect(store.exist?('nope')).to be false
    end
  end

  describe '#delete' do
    it 'removes an entry' do
      store.write('a', 'alpha')
      store.delete('a')
      expect(store.exist?('a')).to be false
    end
  end

  describe 'eviction when max_size is reached' do
    it 'evicts the oldest entry when a new key is added beyond capacity' do
      store.write('a', 'alpha')
      store.write('b', 'beta')
      store.write('c', 'gamma')
      store.write('d', 'delta')

      expect(store.exist?('a')).to be false
      expect(store.exist?('b')).to be true
      expect(store.exist?('c')).to be true
      expect(store.exist?('d')).to be true
    end

    it 'evicts the second-oldest when the oldest slot has already been evicted' do
      store.write('a', 'alpha')
      store.write('b', 'beta')
      store.write('c', 'gamma')
      store.write('d', 'delta') # evicts 'a'
      store.write('e', 'epsilon') # evicts 'b'

      expect(store.exist?('a')).to be false
      expect(store.exist?('b')).to be false
      expect(store.exist?('c')).to be true
      expect(store.exist?('d')).to be true
      expect(store.exist?('e')).to be true
    end

    it 'does not evict when updating an existing key' do
      store.write('a', 'alpha')
      store.write('b', 'beta')
      store.write('c', 'gamma')
      store.write('a', 'updated')

      expect(store.exist?('a')).to be true
      expect(store.exist?('b')).to be true
      expect(store.exist?('c')).to be true
      expect(store.read('a')).to eq 'updated'
    end

    it 'never exceeds max_size' do
      100.times { |i| store.write("key#{i}", "val#{i}") }
      count = (0...100).count { |i| store.exist?("key#{i}") }
      expect(count).to eq 3
    end
  end

  describe 'default max_size' do
    it 'defaults to 500 entries' do
      expect(described_class::DEFAULT_MAX_SIZE).to eq 500
      default_store = described_class.new
      501.times { |i| default_store.write("k#{i}", "v#{i}") }
      count = (0...501).count { |i| default_store.exist?("k#{i}") }
      expect(count).to eq 500
    end
  end
end
