# frozen_string_literal: true

module XSD
  # The complexContent element defines extensions or restrictions
  # on a complex type that contains mixed content or elements only.
  # Parent elements: complexType
  # https://www.w3schools.com/xml/el_complexcontent.asp
  class ComplexContent < BaseObject
    # Optional. Specifies whether character data is allowed to appear between the child elements of this complexType
    # element. Default is false
    # @!attribute mixed
    # @return [Boolean]
    property :mixed, :boolean, default: false

    # Get nested extension
    # @!attribute extension
    # @return [Extension, nil]
    child :extension, :extension

    # Get nested restriction
    # @!attribute restriction
    # @return [Restriction, nil]
    child :restriction, :restriction
  end
end
