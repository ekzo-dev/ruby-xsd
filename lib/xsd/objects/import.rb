# frozen_string_literal: true

module XSD
  # The import element is used to add multiple schemas with different target namespace to a document.
  # Parent elements: schema
  # https://www.w3schools.com/xml/el_import.asp
  class Import < BaseObject
    # Optional. Specifies the URI of the namespace to import
    # @!attribute namespace
    # @return String, nil
    property :namespace, :string

    # Optional. Specifies the URI to the schema for the imported namespace
    # @!attribute schema_location
    # @return String, nil
    property :schemaLocation, :string

    # Get imported schema: the one at the import's location when that one is loaded already; otherwise one known for
    # the namespace, added manually or by another import. Not for the absent namespace: schemas with no target
    # namespace are each a schema of its own (a provider's documents, every one with its own copies of the common
    # types), so every import of it is read from its own location.
    # @return Schema
    def imported_schema
      if schema_location
        located = reader.loaded_schema(schema_location, base: schema.location)
        return located if located
      end

      unless namespace.nil?
        known_schema = reader.schemas_for_namespace(namespace).find { |s| !s.equal?(schema) }
        return known_schema if known_schema
      end

      unless schema_location
        raise ImportError,
              "Schema location not provided for namespace '#{namespace}', use add_schema_xml()/add_schema_node()"
      end

      new_schema = reader.load_schema(schema_location, namespace: namespace, base: schema.location)

      unless namespace == new_schema.target_namespace
        raise ImportError, "Import namespace '#{namespace}' does not match imported schema targetNamespace " \
                           "'#{new_schema.target_namespace}'"
      end

      new_schema
    end
  end
end
