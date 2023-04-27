# frozen_string_literal: true

module XSD
  # The extension element extends an existing simpleType or complexType element.
  # Parent elements: simpleContent, complexContent
  # https://www.w3schools.com/xml/el_extension.asp
  class Extension < BaseObject
    TYPE_PROPERTY = nil

    include Based
    include SimpleTyped
    include AttributeContainer
  end
end
