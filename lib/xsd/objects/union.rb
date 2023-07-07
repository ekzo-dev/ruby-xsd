# frozen_string_literal: true

module XSD
  # The union element defines a simple type as a collection (union) of values from specified simple data types.
  # Parent elements: simpleType
  # https://www.w3schools.com/xml/el_union.asp
  class Union < BaseObject
    # Optional. Specifies a list of built-in data types or simpleType elements defined in a schema
    # @!attribute member_types
    # @return Array<String>
    property :memberTypes, :array, default: [] do |union|
      union.node['memberTypes']&.split(' ')
    end

    # Nested simple and built-in types
    # @return Array<SimpleType, String>
    def types
      @types ||= map_children(:simpleType) + member_types.map do |name|
        object_by_name(:simpleType, name) || name
      end
    end
  end
end
