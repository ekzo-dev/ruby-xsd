# frozen_string_literal: true

module XSD
  # The simpleType element defines a simple type and specifies the constraints and information about the values
  # of attributes or text-only elements.
  # Parent elements: attribute, element, list, restriction, schema, union
  # https://www.w3schools.com/xml/el_simpletype.asp
  class SimpleType < BaseObject
    # Optional. Specifies the name of the attribute. Name and ref attributes cannot both be present
    # @!attribute name
    # @return String
    property :name, :string

    # Nested restriction
    # @!attribute restriction
    # @return Restriction, nil
    child :restriction, :restriction

    # Nested union
    # @!attribute union
    # @return Union, nil
    child :union, :union

    # Nested list
    # @!attribute list
    # @return List, nil
    child :list, :list

    # Determine if this is a linked type
    # @return Boolean
    def linked?
      !name.nil?
    end

    # Get base data type
    # @return String, nil
    def data_type
      if restriction
        if restriction.base
          restriction.base_simple_type&.data_type || strip_prefix(restriction.base)
        else
          restriction.simple_type&.data_type
        end
      elsif union
        types = union.types.map { |type| type.is_a?(String) ? strip_prefix(type) : type.data_type }.uniq
        types.size == 1 ? types.first : types
      else
        # list is always a sting
        'string'
      end
    end
  end
end
