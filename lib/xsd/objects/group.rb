# frozen_string_literal: true

module XSD
  # The group element is used to define a group of elements to be used in complex type definitions.
  # Parent elements: schema, choice, sequence, complexType, restriction (both simpleContent and complexContent),
  # extension (both simpleContent and complexContent)
  # https://www.w3schools.com/xml/el_group.asp
  class Group < BaseObject
    include MinMaxOccurs
    include Referenced

    # Optional. Specifies the name of the attribute. Name and ref attributes cannot both be present
    # @!attribute name
    # @return String
    property :name, :string

    # Nested all object
    # @!attribute all
    # @return All
    child :all, :all

    # Nested choice object
    # @!attribute choice
    # @return Choice
    child :choice, :choice

    # Nested sequence object
    # @!attribute sequence
    # @return Sequence
    child :sequence, :sequence
  end
end
