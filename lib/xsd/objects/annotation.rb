# frozen_string_literal: true

module XSD
  # The annotation element is a top level element that specifies schema comments. The comments serve as inline
  # documentation.
  # Parent elements: Any element
  # https://www.w3schools.com/xml/el_annotation.asp
  class Annotation < BaseObject
    # Nested appinfos
    # @!attribute appinfos
    # @return Array<Appinfo>
    child :appinfos, [:appinfo]

    # Nested documentations
    # @!attribute documentations
    # @return Array<Documentation>
    child :documentations, [:documentation]
  end
end
