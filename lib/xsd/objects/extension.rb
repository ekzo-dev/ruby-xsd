# frozen_string_literal: true

module XSD
  # The extension element extends an existing simpleType or complexType element.
  # Parent elements: simpleContent, complexContent
  # https://www.w3schools.com/xml/el_extension.asp
  class Extension < BaseObject
    TYPE_PROPERTY = nil

    include Based
    include AttributeContainer

    # Nested group
    # @!attribute group
    # @return Group
    child :group, :group

    # Nested all
    # @!attribute all
    # @return All
    child :all, :all

    # Nested choice
    # @!attribute choice
    # @return Choice
    child :choice, :choice

    # Nested sequence
    # @!attribute sequence
    # @return Sequence
    child :sequence, :sequence
  end
end
