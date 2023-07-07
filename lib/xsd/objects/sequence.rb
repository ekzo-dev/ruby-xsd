# frozen_string_literal: true

module XSD
  # The sequence element specifies that the child elements must appear in a sequence.
  # Each child element can occur from 0 to any number of times.
  # Parent elements: group, choice, sequence, complexType, restriction (both simpleContent and complexContent),
  # extension (both simpleContent and complexContent)
  # https://www.w3schools.com/xml/el_sequence.asp
  class Sequence < BaseObject
    include MinMaxOccurs
    include ElementContainer

    # Nested groups
    # @!attribute groups
    # @return Array<Group>
    child :groups, [:group]

    # Nested choices
    # @!attribute choices
    # @return Array<Choice>
    child :choices, [:choice]

    # Nested sequences
    # @!attribute sequences
    # @return Array<Sequence>
    child :sequences, [:sequence]

    # Nested anys
    # @!attribute anys
    # @return Array<Any>
    child :anys, [:any]
  end
end
