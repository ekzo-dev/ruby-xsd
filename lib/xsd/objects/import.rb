# frozen_string_literal: true

module XSD
  # The import element is used to add multiple schemas with different target namespace to a document.
  # Parent elements: schema
  # https://www.w3schools.com/xml/el_import.asp
  class Import < BaseObject
    # Optional. Specifies the URI of the namespace to import
    # @!attribute namespace
    # @return [String, nil]
    property :namespace, :string

    # Optional. Specifies the URI to the schema for the imported namespace
    # @!attribute schema_location
    # @return [String, nil]
    property :schemaLocation, :string

    # Get imported schema
    # @return XSD:Schema
    def imported_schema
      schema = reader.schema_for_namespace(namespace)
      return schema if schema

      unless schema_location
        raise ImportError, "Schema location not provided for namespace '#{namespace}', use add_schema_xml()/add_schema_node()"
      end

      xml = reader.resource_resolver.call(schema_location, namespace)
      schema = reader.add_schema_xml(xml)

      unless namespace == schema.target_namespace
        raise ImportError, 'Import location does not match imported schema targetNamespace'
      end

      schema
    end
  end
end
