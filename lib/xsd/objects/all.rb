# frozen_string_literal: true

module XSD
  # The all element specifies that the child elements can appear in any order and that each child element can
  # occur zero or one time.
  # Parent elements: group, complexType, restriction (both simpleContent and complexContent),
  # extension (both simpleContent and complexContent)
  # https://www.w3schools.com/xml/el_all.asp
  class All < BaseObject
    include MinMaxOccurs
    include ElementContainer
  end
end
