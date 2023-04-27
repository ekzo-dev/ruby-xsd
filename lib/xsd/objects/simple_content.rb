# frozen_string_literal: true

module XSD
  # The simpleContent element contains extensions or restrictions on a text-only complex type or on a simple type as
  # content and contains no elements.
  # Parent elements: complexType
  # https://www.w3schools.com/xml/el_simpleContent.asp
  class SimpleContent < BaseObject
    # Nested extension
    # @!attribute extension
    # @return [Extension, nil]
    child :extension, :extension

    # Nested restriction
    # @!attribute restriction
    # @return [Restriction, nil]
    child :restriction, :restriction
  end
end
