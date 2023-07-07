# frozen_string_literal: true

module XSD
  # The selector element specifies an XPath expression that selects a set of elements for an identity constraint
  # (unique, key, and keyref elements).
  # Parent elements: key, keyref, unique
  # https://www.w3schools.com/xml/el_selector.asp
  class Selector < BaseObject
    # Required. Specifies an XPath expression, relative to the element being declared, that identifies the child
    # elements to which the identity constraint applies
    # @!attribute xpath
    # @return String
    property :xpath, :string, required: true
  end
end
