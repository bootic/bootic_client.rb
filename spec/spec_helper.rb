$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'bootic_client'
require 'byebug'

RSpec.configure do |config|
  config.raise_errors_for_deprecations!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
