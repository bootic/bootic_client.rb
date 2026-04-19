$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'hyperlinked'
require 'byebug'

RSpec.configure do |config|
  config.raise_errors_for_deprecations!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    Hyperlinked.instance_variable_set(:@configuration, nil)
  end
end
