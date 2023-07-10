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
      nil_if_empty(@namespace_prefix ||= namespaces.key(XML_SCHEMA).sub(/^xmlns:?/, ''))
    end

    # Check if namespace is a target namespace
    # @param [String, nil] namespace
    # @return Boolean
    def targets_namespace?(namespace)
      namespace == target_namespace || namespaces[namespace.nil? ? 'xmlns' : "xmlns:#{namespace}"] == target_namespace
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

      (includes + imports).map do |import|
        key = import.respond_to?(:namespace) && import.namespace ? import.namespace : import.schema_location
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

    # Validate XML against current schema
    # @param [String, Pathname, Nokogiri::XML::Document] xml
    def validate_xml(xml)
      # validate input
      raise ValidationError unless xml.is_a?(Nokogiri::XML::Document) || xml.is_a?(Pathname) || xml.is_a?(String)

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

      # if !imported_xsd.empty?
      # imports are explicitly provided - put all files in one tmpdir and update import paths appropriately
      # TODO: save file/path map to display in errors
      Dir.mktmpdir('XSD', reader.tmp_dir) do |dir|
        # create primary xsd file
        file = "#{::SecureRandom.urlsafe_base64}.xsd"

        # create imported xsd files
        recursive_import_xsd(self, file, Set.new) do |f, data|
          File.write("#{dir}/#{f}", data)
        end

        # read schema from tmp file descriptor
        io = File.open("#{dir}/#{file}")
        @schema_validator = create_xml_schema(io)
      end
      # else
      #   @schema_validator = create_xml_schema(schema.node.to_xml)
      # end

      @schema_validator
    end

    # Сформировать имена файлов и содержимое XSD схем для корректной валидации
    # @param [Schema] schema
    # @param [String] file
    # @param [Set] processed
    def recursive_import_xsd(schema, file, processed, &block)
      # handle recursion
      namespace = schema.target_namespace
      return if processed.include?(namespace)

      processed.add(namespace)

      data = schema.node.to_xml

      schema.imports.each do |import|
        name      = "#{::SecureRandom.urlsafe_base64}.xsd"
        location  = import.schema_location
        namespace = import.namespace

        if location
          data = data.sub("schemaLocation=\"#{location}\"", "schemaLocation=\"#{name}\"")
        else
          data = data.sub("namespace=\"#{namespace}\"", "namespace=\"#{namespace}\" schemaLocation=\"#{name}\"")
        end
        recursive_import_xsd(import.imported_schema, name, processed, &block)
      end

      block.call(file, data)
    end

    # Create Nokogiri XML Schema instance with preconfigured options
    # @param [IO, String] io
    def create_xml_schema(io)
      Nokogiri::XML::Schema(io, Nokogiri::XML::ParseOptions.new.nononet)
    end
  end
end
