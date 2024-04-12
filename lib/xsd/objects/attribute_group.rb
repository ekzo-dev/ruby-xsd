# frozen_string_literal: true

module XSD
  # The attributeGroup element is used to group a set of attribute declarations so that they can be incorporated as a
  # group into complex type definitions.
  # Parent elements: attributeGroup, complexType, schema, restriction (both simpleContent and complexContent),
  # extension (both simpleContent and complexContent
  # https://www.w3schools.com/xml/el_attributegroup.asp
  class AttributeGroup < BaseObject
    include Referenced
    include AttributeContainer
    include Named

    # Optional. Specifies the name of the attribute group. Name and ref attributes cannot both be present
    # @!attribute name
    # @return String, nil
    property :name, :string
  end
end
