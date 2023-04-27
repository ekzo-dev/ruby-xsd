# frozen_string_literal: true

module XSD
  # The simpleType element defines a simple type and specifies the constraints and information about the values
  # of attributes or text-only elements.
  # Parent elements: attribute, element, list, restriction, schema, union
  # https://www.w3schools.com/xml/el_simpletype.asp
  class SimpleType < BaseObject
    # Optional. Specifies the name of the attribute. Name and ref attributes cannot both be present
    # @!attribute name
    # @return [String]
    property :name, :string

    # Nested restriction
    # @!attribute restriction
    # @return [Restriction, nil]
    child :restriction, :restriction

    # Nested union
    # @!attribute union
    # @return [Union, nil]
    child :union, :union

    # Nested list
    # @!attribute list
    # @return [List, nil]
    child :list, :list

    # Determine if this is a linked type
    # @return [Boolean]
    def linked?
      !name.nil?
    end
  end
end
