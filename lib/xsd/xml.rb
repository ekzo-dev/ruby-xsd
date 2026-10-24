# frozen_string_literal: true

require 'nokogiri'
require 'net/http'
require 'pathname'
require 'logger'
require 'uri'

module XSD
  class XML
    attr_reader :options, :object_cache, :schemas

    # Matches locations that have to be fetched over the network
    REMOTE_LOCATION = %r{\Ahttps?://}i

    # Legacy resource resolver, kept for backwards compatibility. Resolves absolute paths and URLs only,
    # relative locations are resolved by the reader itself, see #read_resource
    DEFAULT_RESOURCE_RESOLVER = proc do |location, namespace|
      if location.match?(REMOTE_LOCATION)
        Net::HTTP.get(URI(location))
      elsif Pathname.new(location).absolute?
        File.read(location)
      else
        raise ImportError, "Failed to locate import '#{location}'#{" for namespace '#{namespace}'" if namespace}"
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
    # @param [String, Pathname] path
    # @param [Hash] options
    # @return XML
    def self.open(path, **options)
      reader = new(**options)
      reader.add_schema_xml(File.read(path.to_s), location: path.to_s)
      reader
    end

    def initialize(**options)
      @options              = options
      # keyed by node identity, the parsed documents are treated as immutable
      @object_cache         = {}.compare_by_identity
      @schemas              = []
      @schemas_by_location  = {}
      @chameleons           = {}
    end

    def logger
      options[:logger] || default_logger
    end

    # Resolver used to fetch imported/included schemas
    # @return Proc
    def resource_resolver
      @options[:resource_resolver] || DEFAULT_RESOURCE_RESOLVER
    end

    def tmp_dir
      options[:tmp_dir]
    end

    def read_document(xml)
      Nokogiri::XML(xml)
    end

    # Add schema xml to reader instance
    # @param [String] xml
    # @param [String, nil] location Location the xml was read from, used to resolve relative imports
    # @return Schema
    def add_schema_xml(xml, location: nil)
      doc = read_document(xml)
      raise Error, 'Schema node not found, xml does not seem to be a valid XSD' unless doc.root&.name == 'schema'

      add_schema_node(doc.root, location: location)
    end

    # Add schema node to reader instance
    # @param [Nokogiri::XML::Node] node
    # @param [String, nil] location Location the node was read from, used to resolve relative imports
    # @return Schema
    def add_schema_node(node, location: nil)
      raise Error, 'Added schema must be of type Nokogiri::XML::Node' unless node.is_a?(Nokogiri::XML::Node)

      new_schema = Schema.new(options.merge(node: node, reader: self, location: location))
      schemas.push(new_schema)
      # register the schema so that an import/include pointing back at this location reuses it
      @schemas_by_location[location] ||= new_schema if location
      new_schema
    end

    # Load schema referenced by an import/include, reusing an already loaded one when possible.
    #
    # A location written with backslashes (`import\types.xsd`) is read as one written with slashes: a
    # `schemaLocation` is a URI reference, where the separator is `/` alone, but schemas authored on Windows
    # carry such locations, and the tools they were made with accept them. A custom resolver is handed the
    # location so normalized.
    # @param [String] location
    # @param [String, nil] namespace
    # @param [String, nil] base Location of the referencing schema
    # @return Schema
    def load_schema(location, namespace: nil, base: nil)
      raise ImportError, 'Schema location must be provided' if location.nil? || location.empty?

      location = location.tr('\\', '/')
      expanded = expand_location(location, base)
      return @schemas_by_location[expanded] if @schemas_by_location.key?(expanded)

      # a custom resolver is responsible for resolving relative locations on its own
      xml = if options[:resource_resolver]
              options[:resource_resolver].call(location, namespace)
            else
              read_resource(expanded, namespace)
            end

      @schemas_by_location[expanded] = add_schema_xml(xml, location: expanded)
    end

    # The schema already read from a location, relative to a base as an import or an include names it
    # @param [String] location
    # @param [String, nil] base Location of the referencing schema
    # @return Schema, nil
    def loaded_schema(location, base: nil)
      @schemas_by_location[expand_location(location.tr('\\', '/'), base)]
    end

    # Get first added (considered primary) schema
    # @return Schema, nil
    def schema
      schemas.first
    end

    # Get schemas by namespace: those that target it, and what they include — a chameleon schema (one with no
    # target namespace of its own) as a view in this namespace
    # @param [String, nil] namespace
    # @return Array<Schema>
    def schemas_for_namespace(namespace)
      found = []
      # a schema only seen through a chameleon view is not one of the absent namespace
      standalone_schemas.select { |schema| schema.target_namespace == namespace }.each do |schema|
        schema.with_includes.each { |included| found << included unless found.any? { |known| known.equal?(included) } }
      end
      found
    end

    # A schema with no target namespace, seen as part of the namespace of a schema that includes it ("chameleon"
    # include): the same document, with everything it declares in that namespace. One view per schema and
    # namespace, so a schema included into two namespaces declares two sets of definitions.
    # @param [Schema] source
    # @param [String] namespace
    # @return Schema
    def chameleon(source, namespace)
      @chameleons[[source.object_id, namespace]] ||=
        Schema.new(source.options.merge(chameleon_namespace: namespace, chameleon_source: source))
    end

    # The chameleon views made so far
    # @return Array<Schema>
    def chameleons
      @chameleons.values
    end

    # Every namespace the schemas declare definitions in, includes resolved. A schema with no target namespace
    # stands for the absent namespace (nil) only when no schema includes it: otherwise what it declares is part
    # of the namespaces including it.
    # @return Array<String, nil>
    def target_namespaces
      (standalone_schemas + chameleons).map(&:target_namespace).uniq
    end

    # The schemas that stand on their own, includes resolved: all but those only seen through a chameleon view,
    # whose definitions belong to the namespaces including them
    # @return Array<Schema>
    def standalone_schemas
      schemas.each(&:with_includes)
      sources = chameleons.map(&:chameleon_source)
      schemas.reject { |schema| sources.any? { |source| source.equal?(schema) } }
    end

    def [](*args)
      standalone_schemas.each do |schema|
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

    # Read schema contents from an absolute path or URL
    # @param [String] location
    # @param [String, nil] namespace
    # @return String
    def read_resource(location, namespace = nil)
      if location.match?(REMOTE_LOCATION)
        Net::HTTP.get(URI(location))
      elsif File.file?(location)
        File.read(location)
      else
        raise ImportError, "Failed to locate import '#{location}'#{" for namespace '#{namespace}'" if namespace}"
      end
    end

    # Resolve a possibly relative location against the location of the referencing schema
    # @param [String] location
    # @param [String, nil] base
    # @return String
    def expand_location(location, base)
      return location if location.match?(REMOTE_LOCATION) || Pathname.new(location).absolute?
      return location if base.nil?
      return URI.join(base, location).to_s if base.match?(REMOTE_LOCATION)

      Pathname.new(base).dirname.join(location).cleanpath.to_s
    end

    def collect(name, *args)
      standalone_schemas.flat_map { |schema| schema.send(name, *args) }.uniq
    end

    def default_logger
      @default_logger ||= Logger.new($stdout).tap do |logger|
        logger.level = Logger::WARN
      end
    end
  end
end
