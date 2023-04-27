# frozen_string_literal: true

module XSD
  # The list element defines a simple type element as a list of values of a specified data type.
  # Parent elements: simpleType
  # https://www.w3schools.com/xml/el_list.asp
  class List < BaseObject
    TYPE_PROPERTY = :itemType

    include SimpleTyped

    # Specifies the name of a built-in data type or simpleType element defined in this or another schema.
    # This attribute is not allowed if the content contains a simpleType element, otherwise it is required
    # @!attribute item_type
    # @return [String, nil]
    property :itemType, :string
  end
end
