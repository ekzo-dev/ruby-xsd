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

    # Get included schema
    # @return Schema
    def imported_schema
      raise ImportError, 'Schema location not provided for include' unless schema_location

      new_schema = reader.load_schema(schema_location, base: schema.location)

      # an included schema without a target namespace adopts the namespace of the including schema ("chameleon"
      # include): what it declares belongs to that namespace, so it is seen through a view that says so
      if new_schema.target_namespace.nil? && !schema.target_namespace.nil?
        return reader.chameleon(new_schema, schema.target_namespace)
      end

      unless new_schema.target_namespace.nil? || schema.target_namespace == new_schema.target_namespace
        raise ImportError, "Schema targetNamespace '#{schema.target_namespace}' does not match included schema " \
                           "targetNamespace '#{new_schema.target_namespace}'"
      end

      new_schema
    end
  end
end
