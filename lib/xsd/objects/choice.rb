# frozen_string_literal: true

module XSD
  # XML Schema choice element allows only one of the elements contained in the <choice> declaration to be present
  # within the containing element.
  # Parent elements: group, choice, sequence, complexType, restriction (both simpleContent and complexContent),
  # extension (both simpleContent and complexContent)
  # https://www.w3schools.com/xml/el_choice.asp
  class Choice < BaseObject
    include MinMaxOccurs
    include ElementContainer

    # Nested groups
    # @!attribute groups
    # @return [Array<Group>]
    child :groups, [:group]

    # Nested choices
    # @!attribute choices
    # @return [Array<Choice>]
    child :choices, [:choice]

    # Nested sequences
    # @!attribute sequences
    # @return [Array<Sequence>]
    child :sequences, [:sequence]

    # Nested anys
    # @!attribute anys
    # @return [Array<Any>]
    child :anys, [:any]
  end
end
