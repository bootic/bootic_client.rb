require 'spec_helper'

describe BooticClient do
  it "raises if nil client_id" do
    expect {
      BooticClient.configure do |c|
        c.client_id = nil
      end
    }.to raise_error BooticClient::InvalidConfigurationError
  end

  it "raises if nil client_secret" do
    expect {
      BooticClient.configure do |c|
        c.client_secret = nil
      end
    }.to raise_error BooticClient::InvalidConfigurationError
  end

  it "raises if nil cache_store" do
    expect {
      BooticClient.configure do |c|
        c.cache_store = nil
      end
    }.to raise_error BooticClient::InvalidConfigurationError
  end

  it "raises if nil or invalid auth_host" do
    expect {
      BooticClient.configure do |c|
        c.auth_host = nil
      end
    }.to raise_error BooticClient::InvalidConfigurationError

    expect {
      BooticClient.configure do |c|
        c.auth_host = 'not-a-url'
      end
    }.to raise_error BooticClient::InvalidConfigurationError
  end

  it "raises if nil or invalid api_root" do
    expect {
      BooticClient.configure do |c|
        c.api_root = nil
      end
    }.to raise_error BooticClient::InvalidConfigurationError

    expect {
      BooticClient.configure do |c|
        c.api_root = 'not-a-url'
      end
    }.to raise_error BooticClient::InvalidConfigurationError
  end

  it "raises if nil logger" do
    expect {
      BooticClient.configure do |c|
        c.logger = nil
      end
    }.to raise_error BooticClient::InvalidConfigurationError
  end
end
