# frozen_string_literal: true

require 'nokogiri'
require 'net/http'

module XSD
  class XML
    attr_reader :options, :object_cache, :schemas

    DEFAULT_RESOURCE_RESOLVER = proc do |location, namespace|
      if location =~ /^https?:/
        Net::HTTP.get(URI(location))
      elsif Pathname.new(location).absolute?
        File.read(location)
      else
        raise ImportError, "Failed to locate import '#{location}'#{namespace ? " for namespace '#{namespace}'" : ''}"
      end
    end

    CLASS_MAP = {
      'schema'         => Schema,
      'element'        => Element,
      'attribute'      => Attribute,
      'choice'         => Choice,
      'complexType'    => ComplexType,
      'sequence'       => Sequence,
      'simpleContent'  => SimpleContent,
      'complexContent' => ComplexContent,
      'extension'      => Extension,
      'import'         => Import,
      'include'        => Include,
      'simpleType'     => SimpleType,
      'all'            => All,
      'restriction'    => Restriction,
      'group'          => Group,
      'any'            => Any,
      'union'          => Union,
      'attributeGroup' => AttributeGroup,
      'list'           => List,
      'unique'         => Unique,
      'selector'       => Selector,
      'field'          => Field,
      'annotation'     => Annotation,
      'documentation'  => Documentation,
      'appinfo'        => Appinfo,
      'anyAttribute'   => AnyAttribute,
      'key'            => Key,
      'keyref'         => Keyref,
      # Restriction facets
      'minExclusive'   => Facet,
      'minInclusive'   => Facet,
      'maxExclusive'   => Facet,
      'maxInclusive'   => Facet,
      'totalDigits'    => Facet,
      'fractionDigits' => Facet,
      'length'         => Facet,
      'minLength'      => Facet,
      'maxLength'      => Facet,
      'enumeration'    => Facet,
      'whiteSpace'     => Facet,
      'pattern'        => Facet
    }.freeze

    # Create reader from a file path
    # @param [String] path
    # @param [Hash] options
    # @return XML
    def self.open(path, **options)
      reader = new(**options)
      reader.add_schema_xml(File.read(path))
      reader
    end

    def initialize(**options)
      @options      = options
      @object_cache = {}
      @schemas      = []
    end

    def logger
      options[:logger] || default_logger
    end

    def resource_resolver
      @options[:resource_resolver] || DEFAULT_RESOURCE_RESOLVER
    end

    def tmp_dir
      @tmp_dir ||= options[:tmp_dir]
    end

    def read_document(xml)
      Nokogiri::XML(xml)
    end

    # Add schema xml to reader instance
    # @return Schema
    def add_schema_xml(xml)
      doc = read_document(xml)
      raise Error, 'Schema node not found, xml does not seem to be a valid XSD' unless doc.root&.name == 'schema'

      add_schema_node(doc.root)
    end

    # Add schema node to reader instance
    # @return Schema
    def add_schema_node(node)
      raise Error, 'Added schema must be of type Nokogiri::XML::Node' unless node.is_a?(Nokogiri::XML::Node)

      new_schema = Schema.new(options.merge(node: node, reader: self))
      schemas.push(new_schema)
      new_schema
    end

    # Get first added (considered primary) schema
    # @return Schema, nil
    def schema
      schemas.first
    end

    # Get schemas by namespace
    # @param [String, nil] namespace
    # @return Array<Schema>
    def schemas_for_namespace(namespace)
      schemas.select { |schema| schema.target_namespace == namespace }
    end

    def [](*args)
      schemas.each do |schema|
        item = schema[*args]
        return item if item
      end

      nil
    end

    def elements(*args)
      collect(:elements, *args)
    end

    def attributes(*args)
      collect(:attributes, *args)
    end

    def attribute_groups
      collect(:attribute_groups)
    end

    def complex_types
      collect(:complex_types)
    end

    def simple_types
      collect(:simple_types)
    end

    def groups
      collect(:groups)
    end

    private

    def collect(name, *args)
      result = Set.new
      schemas.each { |schema| result.merge(schema.send(name, *args)) }
      result.to_a
    end

    def default_logger
      @default_logger ||= Logger.new($stdout).tap do |logger|
        logger.level = Logger::WARN
      end
    end
  end
end
