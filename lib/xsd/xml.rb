# frozen_string_literal: true

require 'nokogiri'
require 'forwardable'

module XSD
  class XML
    extend Forwardable
    include Generator
    include Validator

    attr_reader :options, :object_cache, :xsd

    # Proxy lookup methods to schema
    def_delegators :schema, :[], :elements, :all_elements, :attributes, :attribute_groups, :all_attributes,
                   :complex_types, :simple_types, :groups, :imports

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

    def initialize(xsd, **options)
      # Base input validation
      raise Error, 'xsd is not a Pathname nor a string' unless xsd.is_a?(Pathname) || xsd.is_a?(String)
      raise Error, 'options is not a hash' unless options.is_a?(Hash)

      @xsd          = xsd
      @options      = options
      @object_cache = {}
    end

    def logger
      options[:logger] || default_logger
    end

    def default_logger
      @default_logger ||= Logger.new($stdout).tap do |logger|
        logger.level = Logger::WARN
      end
    end

    def xml
      @xsd_xml ||= xsd.is_a?(Pathname) ? File.read(xsd) : xsd
    end

    def imported_xsd
      @imported_xsd ||= options[:imported_xsd] || {}
    end

    def tmp_dir
      @tmp_dir ||= options[:tmp_dir]
    end

    def doc
      @doc ||= Nokogiri::XML(xml)
    end

    def schema_node
      raise Error, 'Document root not found, provided document does not seem to be a valid XSD' unless doc.root

      doc.root.name == 'schema' ? doc.root : nil
    end

    def schema
      @schema ||= Schema.new(self.options.merge(node: schema_node, reader: self))
    end

    def schema_for_namespace(_ns)
      schema.schema_for_namespace(_ns)
    end
  end
end
