# frozen_string_literal: true

module XSD
  # Base object
  class BaseObject
    attr_reader :options

    # Objects that can not have nested elements
    NO_ELEMENTS_CONTAINER = %i[annotation simpleType attributeGroup attribute
                               unique union simpleContent list any anyAttribute key keyref].freeze

    # Objects that cannot have nested attributes
    NO_ATTRIBUTES_CONTAINER = %i[annotation unique anyAttribute all
                                 attribute choice sequence group simpleType facet key keyref].freeze

    # Base XMLSchema namespace
    XML_SCHEMA = 'http://www.w3.org/2001/XMLSchema'

    # Namespace map used for all internal xpath queries
    XML_SCHEMA_NS = { 'xs' => XML_SCHEMA }.freeze

    class << self
      attr_reader :properties, :children, :links

      def properties
        @properties ||= {}
      end

      def links
        @links ||= {}
      end

      def children
        @children ||= {}
      end
    end

    def initialize(options = {})
      raise Error, "#{self.class}.new expects a hash parameter" unless options.is_a?(Hash)

      @options = options
      @cache   = {}
    end

    # Get current XML node
    # @return Nokogiri::XML::Node
    def node
      options[:node]
    end

    # Get object string representation
    # @return String
    def inspect
      "#<#{self.class.name} path=#{node.path}>"
    end

    # Optional. Specifies a unique ID for the element
    # @!attribute id
    # @return String
    # property :id, :string
    def id
      node['id']
    end

    # Get current namespaces
    # @return Hash
    def namespaces
      node.namespaces || {}
    end

    # Get child nodes
    # @param [Symbol] name
    # @param [Boolean] deep
    # @return Nokogiri::XML::NodeSet
    def nodes(name = :*, deep = false)
      node.xpath("./#{'/' if deep}xs:#{name}", XML_SCHEMA_NS)
    end

    # Get schemas by namespace or prefix
    # @param [String, nil] ns_or_prefix
    # @return Array<Schema>
    def schemas_for_namespace(ns_or_prefix)
      # resolve namespace for current node if prefix was provided
      prefix = namespaces[['xmlns', (ns_or_prefix == '' ? nil : ns_or_prefix)].compact.join(':')]
      ns = prefix || ns_or_prefix

      if schema.targets_namespace?(ns)
        schema.with_includes
      elsif (import = schema.import_by_namespace(ns))
        # what the imported schema includes is part of its namespace too
        import.imported_schema.with_includes
      else
        raise Error, "Schema not found for namespace '#{ns}' in '#{schema.id || schema.target_namespace}'"
      end
    end

    # Get element or attribute by path
    # @return Element, Attribute, nil
    def [](*args)
      result = self

      args.flatten.each do |curname|
        next if result.nil?

        curname = curname.to_s

        if curname[0] == '@'
          result = result.collect_attributes.find { |attr| definition_match?(attr, curname[1..]) }
        else
          result = result.collect_elements.find { |elem| definition_match?(elem, curname) }
        end
      end

      result
    end

    # Search node by name in all available schemas and return its object
    # @param [Symbol] node_name
    # @param [String] name
    # @return BaseObject, nil
    def object_by_name(node_name, name)
      # get prefix and local name
      name_prefix = get_prefix(name)
      name_local  = strip_prefix(name)

      # do not search for built-in types
      return nil if schema.namespace_prefix == name_prefix

      # determine schema for namespace
      search_schemas = schemas_for_namespace(name_prefix)

      # find the declaration in the schemas of the namespace
      search_schemas.each do |s|
        node = s.declaration_node(node_name, name_local)
        return s.node_to_object(node) if node
      end

      nil
    end

    # Get reader object for node
    # @param [Nokogiri::XML::Node] node
    # @return BaseObject
    def node_to_object(node)
      # check object in cache first; a chameleon view keeps a cache of its own (see Schema#object_cache)
      cache = schema.object_cache
      cached = cache[node]
      return cached if cached

      klass = XML::CLASS_MAP[node.name]
      raise Error, "Object class not found for '#{node.name}'" unless klass

      cache[node] = klass.new(options.merge(node: node, schema: schema))
    end

    # Get xml parent object
    # @return BaseObject, nil
    def parent
      return @parent if defined?(@parent)

      parent_node = node.respond_to?(:parent) ? node.parent : nil

      # the parent may be a document or a node of a foreign schema (e.g. wsdl:types), there is no object for those
      @parent = if parent_node.is_a?(Nokogiri::XML::Element) && XML::CLASS_MAP.key?(parent_node.name)
                  node_to_object(parent_node)
                end
    end

    # Get current schema object
    # @return Schema
    def schema
      options[:schema]
    end

    # Get child objects
    # @param [Symbol] name
    # @return Array<BaseObject>
    def map_children(name)
      nodes(name).map { |node| node_to_object(node) }
    end

    # Get child object
    # @param [Symbol] name
    # @return BaseObject, nil
    def map_child(name)
      map_children(name).first
    end

    # Strip namespace prefix from node name
    # @param [String, nil] name Name to strip from
    # @return String, nil
    def strip_prefix(name)
      name&.include?(':') ? name.split(':').last : name
    end

    # Get namespace prefix from node name
    # @param [String, nil] name Name to strip from
    # @return String, nil
    def get_prefix(name)
      name&.include?(':') ? name.split(':').first : nil
    end

    # Return element documentation
    # @return Array<String>
    def documentation
      @documentation ||= begin
        docs = documentation_for(node)
        if docs.any?
          docs
        elsif is_a?(Referenced) && referenced?
          documentation_for(reference.node)
        else
          []
        end
      end
    end

    # Return documentation for specified node
    # @param [Nokogiri::XML::Node] node
    # @return Array<String>
    def documentation_for(node)
      node.xpath('./xs:annotation/xs:documentation/text()', XML_SCHEMA_NS).map { |x| x.text.strip }
    end

    # Get all available elements on the current stack level
    # @return Array<Element>
    def collect_elements(*)
      @collect_elements ||= if NO_ELEMENTS_CONTAINER.include?(self.class.mapped_name)
                              []
                            elsif is_a?(Referenced) && ref
                              reference.collect_elements
                            else
                              # map children recursive
                              map_children(:*).flat_map do |obj|
                                if obj.is_a?(Element) || obj.is_a?(Any)
                                  obj
                                else
                                  # get elements considering references
                                  (obj.is_a?(Referenced) && obj.ref ? obj.reference : obj).collect_elements
                                end
                              end
                            end
    end

    # Get all available attributes on the current stack level
    # @return Array<Attribute>
    def collect_attributes(*)
      @collect_attributes ||= if NO_ATTRIBUTES_CONTAINER.include?(self.class.mapped_name)
                                []
                              elsif is_a?(Referenced) && ref
                                reference.collect_attributes
                              else
                                # map children recursive
                                map_children(:*).flat_map do |obj|
                                  if obj.is_a?(Attribute) || obj.is_a?(AnyAttribute)
                                    obj
                                  else
                                    # get attributes considering references
                                    (obj.is_a?(Referenced) && obj.ref ? obj.reference : obj).collect_attributes
                                  end
                                end
                              end
    end

    # Get reader instance
    # @return XML
    def reader
      options[:reader]
    end

    protected

    def self.to_underscore(string)
      string.to_s.gsub(/([^A-Z])([A-Z]+)/, '\1_\2').sub(':', '_').downcase.to_sym
    end

    # Define new object property
    # @param [Symbol] name
    # @param [Symbol] type
    # @param [Hash] options
    def self.property(name, type, options = {}, &block)
      method = to_underscore(name)
      properties[method] = {
        name: name,
        type: type,
        resolve: block,
        **options
      }
      define_member_reader(method)
    end

    # Define new object child
    # @param [Symbol] name
    # @param [Symbol, Array<Symbol>] type
    # @param [Hash] options
    def self.child(name, type, options = {})
      method = to_underscore(name)
      children[method] = {
        type: type,
        **options
      }
      define_member_reader(method)
    end

    # Define new object child
    # @param [Symbol] name
    # @param [Symbol] type
    # @param [Hash] options
    def self.link(name, type, options = {})
      method = to_underscore(name)
      links[method] = {
        type: type,
        **options
      }
      define_member_reader(method)
    end

    # A property, link or child is read through a method of its own: reaching it through method_missing costs far
    # more per call, and an object is asked for its members all the time. The method goes in a module of the class's
    # own, so that a method the class defines itself still wins, and is not defined where a method of that name
    # exists already — an ancestor's own keeps answering, as it did when the name went to method_missing.
    # @param [Symbol] method
    def self.define_member_reader(method)
      return if method_defined?(method) || private_method_defined?(method)

      member_readers.define_method(method) do |*args|
        value = read_member(method, args)
        raise NoMethodError.new("undefined method '#{method}' for an instance of #{self.class}", method) if value.equal?(NOT_A_MEMBER)

        value
      end
    end

    # The module a class's member readers are defined in
    # @return Module
    def self.member_readers
      @member_readers ||= Module.new.tap { |readers| include(readers) }
    end

    # What #read_member answers when the name is none of the object's members
    NOT_A_MEMBER = Object.new.freeze

    # Lookup for properties
    # @param [Symbol] method
    # @param [Array] args
    def method_missing(method, *args)
      value = read_member(method, args)
      value.equal?(NOT_A_MEMBER) ? super : value
    end

    # The value of a property, link or child, cached: from the node, through a reference, or by its name in the
    # schemas. A member reader and method_missing both come here.
    # @param [Symbol] method
    # @param [Array] args
    # @return Object, NOT_A_MEMBER
    def read_member(method, args)
      # check cache first, nil and false results are cached as well
      return @cache[method] if @cache.key?(method)

      # check for property first
      if (property = self.class.properties[method])
        return @cache[method] = property_value(property, method, args)
      end

      # if object has ref it cannot contain any type and children, so proxy call to target object
      if node['ref'] && method != :ref && method != :reference
        return @cache[method] = reference.send(method, *args)
      end

      # then check for linked types
      if (link = self.class.links[method])
        name = link[:property] ? send(link[:property]) : nil
        if name
          return @cache[method] = object_by_name(link[:type], name)
        elsif is_a?(Restriction) && %i[base_simple_type base_complex_type].include?(method)
          # handle restriction without base
          return @cache[method] = nil
        end
      end

      # last check for nested objects
      if (child = self.class.children[method])
        result = child[:type].is_a?(Array) ? map_children(child[:type][0]) : map_child(child[:type])
        return @cache[method] = result
      end

      NOT_A_MEMBER
    end

    # Does object has property/link/child?
    # @param [Symbol] method
    # @param [Boolean] include_private
    def respond_to_missing?(method, include_private = false)
      !self.class.properties[method].nil? || !self.class.links[method].nil? ||
        !self.class.children[method].nil? || super
    end

    # Get mapped element name
    # @return Symbol
    def self.mapped_name
      @mapped_name ||= begin
        name = self.name.split('::').last
        name[0] = name[0].downcase
        name.to_sym
      end
    end

    # Return string if it is not empty, or nil otherwise
    # @param [String, nil] string
    # @return String, nil
    def nil_if_empty(string)
      string && string.empty? ? nil : string
    end

    private

    # Resolve property value from the node attribute, resolver block, reference or default
    # @param [Hash] property
    # @param [Symbol] method
    # @param [Array] args
    def property_value(property, method, args)
      value = property[:resolve] ? property[:resolve].call(self) : node[property[:name].to_s]
      return cast_property_value(property, value) unless value.nil?

      # if object has reference - search property in referenced object
      return reference.send(method, *args) if node['ref']

      property[:default].is_a?(Proc) ? instance_eval(&property[:default]) : property[:default]
    end

    # Cast raw attribute value to the declared property type
    # @param [Hash] property
    # @param [String] value
    def cast_property_value(property, value)
      case property[:type]
      when :integer
        property[:name] == :maxOccurs && value == 'unbounded' ? :unbounded : value.to_i
      when :boolean
        value == 'true'
      else
        value
      end
    end

    def definition_match?(definition, query)
      # namespace included in query
      if query.start_with?('{')
        parts = query[1..].split('}')
        raise Error, "Invalid element/attribute query: #{query}" if parts.size != 2

        namespace, name = parts

        return false if nil_if_empty(namespace) != definition.namespace
      else
        name = query
      end

      name == '*' || definition.name == name
    end
  end
end
