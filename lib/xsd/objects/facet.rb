# frozen_string_literal: true

module XSD
  # Virtual object for all restriction facets
  # Parent elements: restriction
  class Facet < BaseObject
    # Returns facet value
    # @!attribute value
    # @return [String]
    property :value, :string
  end
end
