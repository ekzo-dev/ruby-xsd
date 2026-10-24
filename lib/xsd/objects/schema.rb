# frozen_string_literal: true

require 'tmpdir'
require 'securerandom'

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

    # Target namespace of the schema. For a chameleon view (see XML#chameleon), the namespace of the schema
    # that includes it — the one everything it declares belongs to.
    # @return String, nil
    def target_namespace
      return options[:chameleon_namespace] if chameleon?

      method_missing(:target_namespace)
    end

    # Is this a schema with no target namespace, seen as part of the namespace of a schema including it?
    # @return Boolean
    def chameleon?
      options.key?(:chameleon_namespace)
    end

    # The schema a chameleon view is a view of
    # @return Schema, nil
    def chameleon_source
      options[:chameleon_source]
    end

    # Objects made of this schema's nodes. A chameleon view keeps its own: the same node is a different
    # definition in each namespace that includes it.
    # @return Hash
    def object_cache
      chameleon? ? (@object_cache ||= {}.compare_by_identity) : reader.object_cache
    end

    # The node of a top-level declaration of this schema, by its kind and name — what a reference by name looks up
    # (BaseObject#object_by_name). The children are indexed in one pass on the first lookup: a query per lookup
    # scans all of them again, and a large schema is looked up in once for every reference to it.
    # @param [Symbol, String] node_name kind of declaration: complexType, simpleType, element, group, ...
    # @param [String] name local name
    # @return Nokogiri::XML::Element, nil
    def declaration_node(node_name, name)
      @declaration_nodes ||= node.element_children.each_with_object({}) do |child, index|
        next unless child.namespace&.href == XML_SCHEMA

        # the first one, as a query would find it
        index[[child.name, child['name']]] ||= child
      end
      @declaration_nodes[[node_name.to_s, name]]
    end

    # This schema and every schema it includes, those included in turn too
    # @return Array<Schema>
    def with_includes
      found = [self]
      found.each do |schema|
        schema.includes.each do |include|
          included = include.imported_schema
          found << included unless found.any? { |known| known.equal?(included) }
        end
      end
      found
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

    # Get target namespace prefix
    # @return String, nil
    def target_namespace_prefix
      nil_if_empty(@target_namespace_prefix ||= namespaces.key(target_namespace)&.sub(/^xmlns:?/, '') || '')
    end

    # Get schema namespace prefix
    # @return String, nil
    def namespace_prefix
      nil_if_empty(@namespace_prefix ||= namespaces.key(XML_SCHEMA)&.sub(/^xmlns:?/, '') || '')
    end

    # Location the schema was read from, used to resolve relative import/include locations
    # @return String, nil
    def location
      options[:location]
    end

    # Check if namespace is a target namespace
    # @param [String, nil] namespace
    # @return Boolean
    def targets_namespace?(namespace)
      key = namespace.nil? ? 'xmlns' : "xmlns:#{namespace}"
      # a prefix names a namespace only when the schema declares it: looking up a namespace URI as a prefix finds
      # nothing, and nothing must not pass for the absent target namespace of a schema that has none
      namespace == target_namespace || (namespaces.key?(key) && namespaces[key] == target_namespace) ||
        # an unqualified name in a chameleon schema names something of the namespace it was included into
        (chameleon? && namespace.nil? && !namespaces.key?('xmlns'))
    end

    # Override map_children on schema to get objects from all loaded schemas
    # @param [Symbol] name
    # @param [Hash] cache Schema nodes already visited, guards against import/include cycles
    # @return Array<BaseObject>
    def map_children(name, cache = {}.compare_by_identity)
      cache[self] = true
      super(name) + import_map_children(name, cache)
    end

    # Get children from all loaded schemas
    # @param [Symbol] name
    # @param [Hash] cache
    # @return Array<BaseObject>
    def import_map_children(name, cache)
      return [] if %i[import include].include?(name.to_sym)

      (includes + imports).flat_map do |import|
        imported = import.imported_schema
        next [] if cache.key?(imported)

        imported.map_children(name, cache)
      end
    end

    # Get import by namespace or prefix
    # @param [String, nil] ns_or_prefix
    # @return Import
    def import_by_namespace(ns_or_prefix)
      aliases = [
        ns_or_prefix,
        namespaces["xmlns:#{(ns_or_prefix || '').gsub(/^xmlns:/, '')}"]
      ].compact

      imports.find { |import| aliases.include?(import.namespace) }
    end

    # Validate XML against current schema
    # @param [String, Pathname, Nokogiri::XML::Document] xml
    def validate_xml(xml)
      # validate input
      unless xml.is_a?(Nokogiri::XML::Document) || xml.is_a?(Pathname) || xml.is_a?(String)
        raise ValidationError, "XML must be a String, Pathname or Nokogiri::XML::Document, got #{xml.class}"
      end

      begin
        document = xml.is_a?(Nokogiri::XML::Document) ? xml : Nokogiri::XML(xml)
      rescue Nokogiri::XML::SyntaxError => e
        raise ValidationError, e
      end

      errors = schema_validator.validate(document)
      raise ValidationError, errors.map(&:message).join('; ') if errors.any?
    end

    # Validate current schema against XMLSchema 1.0
    def validate
      begin
        schema_validator
      rescue Nokogiri::XML::SyntaxError => e
        # TODO: display import map name for imported_xsd
        message = e.message + (e.file ? " in file '#{File.basename(e.file)}'" : '')
        raise ValidationError, message
      end
    end

    private

    # Get Nokogiri::XML::Schema object to validate against
    # @return Nokogiri::XML::Schema
    def schema_validator
      return @schema_validator if @schema_validator

      # imports/includes are resolved by the reader, so put all schemas in one tmpdir with rewritten locations
      Dir.mktmpdir('XSD', reader.tmp_dir) do |dir|
        file = recursive_import_xsd(self, {}) do |name, data|
          File.write(File.join(dir, name), data, encoding: Encoding::UTF_8)
        end

        # read schema from tmp file descriptor
        File.open(File.join(dir, file)) { |io| @schema_validator = create_xml_schema(io) }
      end

      @schema_validator
    end

    # Write the schema and all of its imports/includes as a flat set of files with rewritten locations
    # @param [Schema] schema
    # @param [Hash] processed Maps already written schema nodes to generated file names
    # @return String Name of the file the schema was written to
    def recursive_import_xsd(schema, processed, &block)
      # handle recursion, schemas are identified by node because includes share the target namespace
      return processed[schema.node] if processed.key?(schema.node)

      file = "#{::SecureRandom.urlsafe_base64}.xsd"
      processed[schema.node] = file

      node       = schema_node_with_namespaces(schema)
      references = schema.imports + schema.includes
      nodes      = node.xpath('./xs:import', XML_SCHEMA_NS).to_a + node.xpath('./xs:include', XML_SCHEMA_NS).to_a

      # point every import/include to the generated file of the referenced schema
      references.zip(nodes).each do |reference, reference_node|
        next if reference_node.nil?

        reference_node['schemaLocation'] = recursive_import_xsd(reference.imported_schema, processed, &block)
      end

      # always serialize as UTF-8 with an explicit declaration, the source document may use another encoding
      block.call(file, %(<?xml version="1.0" encoding="UTF-8"?>\n#{node.to_xml(encoding: 'UTF-8')}))

      file
    end

    # Get a detached copy of the schema node with all inherited namespaces declared on it
    # @param [Schema] schema
    # @return Nokogiri::XML::Node
    def schema_node_with_namespaces(schema)
      node = schema.node.dup
      prefixes = schema.node.namespace_definitions.map(&:prefix)

      schema.node.namespaces.each do |attr, ns|
        prefix = attr == 'xmlns' ? nil : attr.sub('xmlns:', '')
        # add_namespace_definition does not work on a detached node, declare the namespace as an attribute instead
        node[attr] = ns unless prefixes.include?(prefix)
      end

      node
    end

    # Create Nokogiri XML Schema instance with preconfigured options
    # @param [IO, String] io
    def create_xml_schema(io)
      Nokogiri::XML::Schema(io, Nokogiri::XML::ParseOptions.new.nononet)
    end
  end
end
