# frozen_string_literal: true

require 'nokogiri'
require 'net/http'

module XSD
  class XML
    include Generator
    include Validator

    attr_reader :options, :object_cache, :schemas, :namespace_prefixes

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

    def self.open(path, **options)
      reader = new(**options)
      reader.add_schema_xml(File.read(path))
      reader
    end

    def initialize(**options)
      @options            = options
      @object_cache       = {}
      @schemas            = []
      @namespace_prefixes = {}
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

    # Get imported schema
    # @return XSD:Schema
    def add_schema_xml(xml)
      doc = read_document(xml)
      raise Error, 'Schema node not found, xml does not seem to be a valid XSD' unless doc.root&.name == 'schema'

      add_schema_node(doc.root)
    end

    # Get imported schema
    # @return Schema
    def add_schema_node(node)
      raise Error, 'Added schema must be of type Nokogiri::XML::Node' unless node.is_a?(Nokogiri::XML::Node)

      schema = Schema.new(self.options.merge(node: node, reader: self))
      schemas.push(schema)

      schema
    end

    # Add prefixes defined outside of processed schemas, for example in WSDL document
    # @param [String] prefix
    # @param [String] namespace
    def add_namespace_prefix(prefix, namespace)
      @namespace_prefixes[prefix] = namespace
    end

    # Get first added (considered primary) schema
    # @return Schema, nil
    def schema
      schemas.first
    end

    # Get schema by namespace or namespace prefix
    # @return Schema, nil
    def schema_for_namespace(namespace)
      namespace = namespace_prefixes[namespace] if namespace_prefixes.key?(namespace)
      schemas.find { |schema| schema.target_namespace == namespace }
    end

    def [](*args)
      schemas.each do |schema|
        item = schema[*args]
        return item if item
      end

      nil
    end

    def all_elements(*args)
      collect(:all_elements, *args)
    end

    def all_attributes(*args)
      collect(:all_attributes, *args)
    end

    def all_attribute_groups
      collect(:attribute_groups)
    end

    def all_complex_types
      collect(:complex_types)
    end

    def all_simple_types
      collect(:simple_types)
    end

    def all_groups
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
