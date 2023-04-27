# frozen_string_literal: true

module XSD
  # The documentation element is used to enter text comments in a schema.
  # Parent elements: annotation
  # https://www.w3schools.com/xml/el_documentation.asp
  class Documentation < BaseObject
    # Optional. A URI reference that specifies the source of the application information
    # @!attribute source
    # @return [String]
    property :source, :string

    # Optional. Specifies the language used in the contents
    # @!attribute xml_lang
    # @return [String]
    property :'xml:lang', :string
  end
end
