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
      @options = options
      @cache = {}

      raise Error, "#{self.class}.new expects a hash parameter" unless @options.is_a?(Hash)
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
    # @return Nokogiri::XML::NodeSet
    def nodes(name = :*, deep = false)
      node.xpath("./#{deep ? '/' : ''}xs:#{name}", { 'xs' => XML_SCHEMA })
    end

    # Get schemas by namespace or prefix
    # @param [String, nil] ns_or_prefix
    # @return Array<Schema>
    def schemas_for_namespace(ns_or_prefix)
      # resolve namespace for current node if prefix was provided
      prefix = node.namespaces["xmlns:#{ns_or_prefix}"]
      ns = prefix || ns_or_prefix

      if schema.targets_namespace?(ns)
        [schema, *schema.includes.map(&:imported_schema)]
      elsif (import = schema.import_by_namespace(ns))
        [import.imported_schema]
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
      name_local = strip_prefix(name)

      # do not search for built-in types
      return nil if schema.namespace_prefix == name_prefix

      # determine schema for namespace
      search_schemas = schemas_for_namespace(name_prefix)

      # find element in target schema
      search_schemas.each do |s|
        node = s.node.at_xpath("./xs:#{node_name}[@name=\"#{name_local}\"]", { 'xs' => XML_SCHEMA })
        return s.node_to_object(node) if node
      end

      nil
    end

    # Get reader object for node
    # @param [Nokogiri::XML::Node]
    # @return BaseObject
    def node_to_object(node)
      # check object in cache first
      return reader.object_cache[node.object_id] if reader.object_cache[node.object_id]

      klass = XML::CLASS_MAP[node.name]
      raise Error, "Object class not found for '#{node.name}'" unless klass

      reader.object_cache[node.object_id] = klass.new(options.merge(node: node, schema: schema))
    end

    # Get xml parent object
    # @return BaseObject, nil
    def parent
      node.respond_to?(:parent) && node.parent ? node_to_object(node.parent) : nil
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
      documentation_for(node)
    end

    # Return documentation for specified node
    # @param [Nokogiri::XML::Node] node
    # @return Array<String>
    def documentation_for(node)
      node.xpath('./xs:annotation/xs:documentation/text()', { 'xs' => XML_SCHEMA }).map { |x| x.text.strip }
    end

    # Get all available elements on the current stack level
    # @return Array<Element>
    def collect_elements(*)
      return @collect_elements if @collect_elements

      r = if NO_ELEMENTS_CONTAINER.include?(self.class.mapped_name)
            []
          elsif is_a?(Referenced) && ref
            reference.collect_elements
          else
            # map children recursive
            map_children(:*).map do |obj|
              if obj.is_a?(Element)
                obj
              else
                # get elements considering references
                (obj.is_a?(Referenced) && obj.ref ? obj.reference : obj).collect_elements
              end
            end.flatten
          end

      @collect_elements = r
    end

    # Get all available attributes on the current stack level
    # @return Array<Attribute>
    def collect_attributes(*)
      return @collect_attributes if @collect_attributes

      r = if NO_ATTRIBUTES_CONTAINER.include?(self.class.mapped_name)
            []
          elsif is_a?(Referenced) && ref
            reference.collect_attributes
          else
            # map children recursive
            map_children(:*).map do |obj|
              if obj.is_a?(Attribute)
                obj
              else
                # get attributes considering references
                (obj.is_a?(Referenced) && obj.ref ? obj.reference : obj).collect_attributes
              end
            end.flatten
          end

      @collect_attributes = r
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
      properties[to_underscore(name)] = {
        name: name,
        type: type,
        resolve: block,
        **options
      }
    end

    # Define new object child
    # @param [Symbol] name
    # @param [Symbol, Array<Symbol>] type
    # @param [Hash] options
    def self.child(name, type, options = {})
      children[to_underscore(name)] = {
        type: type,
        **options
      }
    end

    # Define new object child
    # @param [Symbol] name
    # @param [Symbol] type
    # @param [Hash] options
    def self.link(name, type, options = {})
      links[to_underscore(name)] = {
        type: type,
        **options
      }
    end

    # Lookup for properties
    # @param [Symbol] method
    # @param [Array] args
    def method_missing(method, *args)
      # check cache first
      return @cache[method] if @cache[method]

      # check for property first
      if (property = self.class.properties[method])
        value = property[:resolve] ? property[:resolve].call(self) : node[property[:name].to_s]
        result = if value.nil?
                   # if object has reference - search property in referenced object
                   node['ref'] ? reference.send(method, *args) : property[:default]
                 else
                   case property[:type]
                   when :integer
                     property[:name] == :maxOccurs && value == 'unbounded' ? :unbounded : value.to_i
                   when :boolean
                     value == 'true'
                   else
                     value
                   end
                 end
        return @cache[method] = result
      end

      # if object has ref it cannot contain any type and children, so proxy call to target object
      if node['ref'] && method != :ref && method != :reference
        return reference.send(method, *args)
      end

      # then check for linked types
      if (link = self.class.links[method])
        name = link[:property] ? send(link[:property]) : nil
        if name
          return @cache[method] = object_by_name(link[:type], name)
        elsif is_a?(Restriction) && method == :base_simple_type
          # handle restriction without base
          return nil
        end
      end

      # last check for nested objects
      if (child = self.class.children[method])
        result = child[:type].is_a?(Array) ? map_children(child[:type][0]) : map_child(child[:type])
        return @cache[method] = result
      end

      super
      # api = self.class.properties.keys + self.class.links.keys + self.class.children.keys
      # raise Error, "Tried to access unknown object '#{method}' on '#{self.class.name}'. Available options are: #{api}"
    end

    # Does object has property/link/child?
    # @param [Symbol] method
    # @param [Array] args
    def respond_to_missing?(method, *args)
      self.class.properties[method] || self.class.links[method] || self.class.children[method] || super
    end

    # Get mapped element name
    # @return Symbol
    def self.mapped_name
      # @mapped_name ||= XML::CLASS_MAP.each { |k, v| return k.to_sym if v == self }
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
      string&.empty? ? nil : string
    end

    private

    def definition_match?(definition, query)
      actual_definition = definition.referenced? ? definition.reference : definition

      if query.start_with?('{')
        parts = query[1..].split('}')
        raise Error, "Invalid element/attribute query: #{query}" if parts.size != 2

        namespace, name = parts

        return false if namespace != actual_definition.namespace
      else
        name = query
      end

      name == '*' || actual_definition.name == name
    end
  end
end
