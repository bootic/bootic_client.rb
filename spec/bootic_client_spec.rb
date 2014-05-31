require 'spec_helper'

describe BooticClient do
  it 'should have a version number' do
    BooticClient::VERSION.should_not be_nil
  end

end
