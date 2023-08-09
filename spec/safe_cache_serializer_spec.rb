require 'spec_helper'

describe BooticClient::Client::SafeCacheSerializer do
  context 'deserializing existing non-base64 content' do
    it 'does not attempt Base64 decoding' do
      result = described_class.load('{"headers": {"foo": 1}, "body": "hello"}')
      expect(result['body']).to eq 'hello'
    end
  end

  context 'Base64-encoding and decoding' do
    it 'decodes body if flagged as Base64' do
      body = Base64.strict_encode64('hello')
      encoded = %({"headers": {"foo": 1}, "body": "__booticclient__base64__:#{body}"})
      result = described_class.load(encoded)
      expect(result['body']).to eq 'hello'
    end

    it 'encodes as Base64 with flag prefix' do
      data = Base64.strict_encode64('{"headers": {"foo": 1}, "body": "hello"}')
      encoded = described_class.dump({headers: {foo: 1}, body: 'hello'})
      parsed = JSON.load(encoded)
      expect(parsed['body']).to eq "__booticclient__base64__:#{Base64.strict_encode64('hello')}"
    end

    it 'encodes and decodes' do
      encoded = described_class.dump({headers: {foo: 1}, body: 'hello'})
      decoded = described_class.load(encoded)
      expect(decoded['body']).to eq 'hello'
    end
  end
end
