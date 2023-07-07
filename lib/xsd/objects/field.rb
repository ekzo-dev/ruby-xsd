# frozen_string_literal: true

module XSD
  # The field element specifies an XPath expression that specifies the value used to define an identity constraint.
  # Parent elements: key, keyref, unique
  # https://www.w3schools.com/xml/el_field.asp
  class Field < BaseObject
    # Required. Identifies a single element or attribute whose content or value is used for the constraint
    # @!attribute xpath
    # @return String
    property :xpath, :string, required: true
  end
end
