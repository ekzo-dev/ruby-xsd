# frozen_string_literal: true

module XSD
  # The unique element defines that an element or an attribute value must be unique within the scope.
  # Parent elements: element
  # https://www.w3schools.com/xml/el_unique.asp
  class Key < BaseObject
    # The name of the key element.
    # The name must be a no-colon-name (NCName) as defined in the XML Namespaces specification.
    # The name must be unique within an identity constraint set. Required.
    # @!attribute name
    # @return String
    property :name, :string, required: true

    # Get nested selector object
    # @!attribute selector
    # @return Selector
    child :selector, :selector

    # Get nested field objects
    # @!attribute fields
    # @return Array<Field>
    child :fields, [:field]
  end
end
