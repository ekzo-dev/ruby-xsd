# frozen_string_literal: true

module XSD
  # The include element is used to add multiple schemas with the same target namespace to a document.
  # Parent elements: schema
  # https://www.w3schools.com/xml/el_include.asp
  class Include < BaseObject
    # Required. Specifies the URI to the schema to include in the target namespace of the containing schema
    # @!attribute schema_location
    # @return String
    property :schemaLocation, :string

    # Get imported schema
    # @return Schema
    def imported_schema
      # cache included schema locally as it has no unique namespace to check in global registry
      return @imported_schema if @imported_schema

      xml = reader.resource_resolver.call(schema_location)
      new_schema = reader.add_schema_xml(xml)

      unless schema.target_namespace == new_schema.target_namespace
        raise ImportError, 'Schema targetNamespace does not match included schema targetNamespace'
      end

      @imported_schema = new_schema
    end
  end
end
