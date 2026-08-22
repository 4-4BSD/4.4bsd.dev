# frozen_string_literal: true

require "rspec"
require "rack/test"
require_relative "../config/boot"

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  # Isolate each example from the previous agent data.
  config.before(:each) do
    Raven::Agents::Beastie.delete_all
  end
end