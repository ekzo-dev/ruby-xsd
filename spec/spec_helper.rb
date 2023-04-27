# frozen_string_literal: true

require 'xsd'

require_relative 'support/helper_methods'

SPEC_PATH = File.dirname(__FILE__).to_s

RSpec.configure do |config|
  include HelperMethods

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
