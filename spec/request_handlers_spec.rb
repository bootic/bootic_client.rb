require 'spec_helper'
require 'bootic_client/request_handlers'

describe BooticClient::RequestHandlers::Set do
  let(:h1) do
    Proc.new do |resp, _client|
      if resp.headers['Content-Type'] =~ /json/
        'H1'
      end
    end
  end
  let(:h2) do
    Proc.new do |resp, _client|
      if resp.headers['Content-Type'] =~ /text/
        'H2'
      end
    end
  end
  let(:h3) do
    Proc.new do |resp, _client|
      if resp.headers['Content-Type'] =~ /json/
        'not found, theres a previous json one'
      end
    end
  end

  it 'initializes with default handlers' do
    set = described_class.new([h1])
    expect(set.to_a).to eq [h1]
  end

  describe '#resolve' do
    it 'finds first matching handler and returns result' do
      set = described_class.new([h1, h2, h3])

      text_resp = instance_double(::Faraday::Response, headers: {'Content-Type' => 'text/plain'})
      expect(set.resolve(text_resp, nil)).to eq 'H2'

      json_resp = instance_double(::Faraday::Response, headers: {'Content-Type' => 'application/json'})
      expect(set.resolve(json_resp, nil)).to eq 'H1'
    end

    it 'returns raw response if no handler found' do
      set = described_class.new([h1, h2, h3])
      img_resp = instance_double(::Faraday::Response, headers: {'Content-Type' => 'image/jpeg'})
      expect(set.resolve(img_resp, nil)).to eq img_resp
    end
  end

  describe '#add' do
    it 'adds handlers' do
      set = described_class.new

      text_resp = instance_double(::Faraday::Response, headers: {'Content-Type' => 'text/plain'})
      expect(set.resolve(text_resp, nil)).to eq text_resp

      set.add(h2)
      expect(set.resolve(text_resp, nil)).to eq 'H2'
    end
  end
end
