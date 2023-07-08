# frozen_string_literal: true

module XSD
  # The schema element defines the root element of a schema.
  # Parent elements: NONE
  # https://www.w3schools.com/xml/el_schema.asp
  class Schema < BaseObject
    include AttributeContainer
    include ElementContainer

    # Optional. The form for attributes declared in the target namespace of this schema. The value must be "qualified"
    # or "unqualified". Default is "unqualified". "unqualified" indicates that attributes from the target namespace
    # are not required to be qualified with the namespace prefix. "qualified" indicates that attributes from the target
    # namespace must be qualified with the namespace prefix
    # @!attribute attribute_form_default
    # @return String
    property :attributeFormDefault, :string, default: 'unqualified'

    # Optional. The form for elements declared in the target namespace of this schema. The value must be "qualified"
    # or "unqualified". Default is "unqualified". "unqualified" indicates that elements from the target namespace are
    # not required to be qualified with the namespace prefix. "qualified" indicates that elements from the target
    # namespace must be qualified with the namespace prefix
    # @!attribute element_form_default
    # @return String
    property :elementFormDefault, :string, default: 'unqualified'

    # Optional. Specifies the default value of the block attribute on element and complexType elements in the target
    # namespace. The block attribute prevents a complex type (or element) that has a specified type of derivation from
    # being used in place of this complex type. This value can contain #all or a list that is a subset of extension,
    # restriction, or substitution:
    #   extension - prevents complex types derived by extension
    #   restriction - prevents complex types derived by restriction
    #   substitution - prevents substitution of elements
    #   #all - prevents all derived complex types
    # @!attribute block_default
    # @return String
    property :blockDefault, :string

    # Optional. Specifies the default value of the final attribute on element, simpleType, and complexType elements in
    # the target namespace. The final attribute prevents a specified type of derivation of an element, simpleType, or
    # complexType element. For element and complexType elements, this value can contain #all or a list that is a subset
    # of extension or restriction. For simpleType elements, this value can additionally contain list and union:
    #   extension - prevents derivation by extension
    #   restriction - prevents derivation by restriction
    #   list - prevents derivation by list
    #   union - prevents derivation by union
    #   #all - prevents all derivation
    # @!attribute final_default
    # @return String
    property :finalDefault, :string

    # Optional. A URI reference of the namespace of this schema
    # @!attribute target_namespace
    # @return String
    property :targetNamespace, :string

    # Optional. Specifies the version of the schema
    # @!attribute version
    # @return String
    property :version, :string

    # A URI reference that specifies one or more namespaces for use in this schema. If no prefix is assigned, the schema
    # components of the namespace can be used with unqualified references
    # @!attribute xmlns
    # @return String
    property :xmlns, :string

    # Global complex types
    # @!attribute complex_types
    # @return Array<ComplexType>
    child :complex_types, [:complexType]

    # Global simple types
    # @!attribute simple_types
    # @return Array<SimpleType>
    child :simple_types, [:simpleType]

    # Global groups
    # @!attribute groups
    # @return Array<Group>
    child :groups, [:group]

    # Schema imports
    # @!attribute imports
    # @return Array<Import>
    child :imports, [:import]

    # Schema includes
    # @!attribute includes
    # @return Array<Include>
    child :includes, [:include]

    # Get current schema object
    # @return Schema
    def schema
      self
    end

    # Get all available elements on the current stack level, for schema same as elements
    # @return Array<Element>
    def collect_elements(*)
      elements
    end

    # Get all available attributes on the current stack level, for schema same as attributes
    # @return Array<Attribute>
    def collect_attributes(*)
      attributes
    end

    # Get target namespace prefix. There may be more than one prefix, but we return only first defined
    # @return String
    def target_namespace_prefix
      @target_namespace_prefix ||= namespaces.key(target_namespace)&.sub(/^xmlns:?/, '') || ''
    end

    # Get schema namespace prefix
    # @return String
    def namespace_prefix
      @namespace_prefix ||= namespaces.key(XML_SCHEMA).sub(/^xmlns:?/, '')
    end

    # Check if namespace is a target namespace
    # @param [String] namespace
    # @return Boolean
    def targets_namespace?(namespace)
      namespace == target_namespace || namespaces[namespace.empty? ? 'xmlns' : "xmlns:#{namespace}"] == target_namespace
    end

    # Override map_children on schema to get objects from all loaded schemas
    # @param [Symbol] name
    # @return Array<BaseObject>
    def map_children(name, cache = {})
      super(name) + import_map_children(name, cache)
    end

    # Get children from all loaded schemas
    # @param [Symbol] name
    # @return Array<BaseObject>
    def import_map_children(name, cache)
      return [] if %i[import include].include?(name.to_sym)

      (imports + includes).map do |import|
        key = import.namespace || include.schema_location
        if cache.key?(key)
          nil
        else
          cache[key] = true
          import.imported_schema.map_children(name, cache)
        end
      end.compact.flatten
    end

    # Get import by namespace
    # @return Import
    def import_by_namespace(ns)
      aliases = [ns, namespaces["xmlns:#{(ns || '').gsub(/^xmlns:/, '')}"], reader.namespace_prefixes[ns]].compact
      imports.find { |import| aliases.include?(import.namespace) }
    end
  end
end
