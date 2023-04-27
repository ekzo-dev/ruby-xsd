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

    # Optional. Specifies a unique ID for the element
    # @!attribute id
    # @return [String]
    # property :id, :string
    def id
      node['id']
    end

    def initialize(options = {})
      @options = options
      @cache   = {}

      raise Error, "#{self.class}.new expects a hash parameter" unless @options.is_a?(Hash)
    end

    # Get current XML node
    # @return [Nokogiri::XML::Node]
    def node
      options[:node]
    end

    # Get current namespaces
    # @return [Hash]
    def namespaces
      node.namespaces || {}
    end

    # Get child nodes
    # @param [Symbol] name
    # @return [Nokogiri::XML::NodeSet]
    def nodes(name = :*)
      node.xpath("./xs:#{name}", { 'xs' => XML_SCHEMA })
    end

    # Get schema object for specified namespace prefix
    # @param [String] prefix
    # @return [Schema]
    def schema_for_namespace(prefix)
      if schema.targets_namespace?(prefix)
        schema
      elsif (import = schema.import_by_namespace(prefix))
        import.imported_reader.schema
      else
        raise Error, "Schema not found for namespace '#{prefix}' in '#{schema.id || schema.target_namespace}'"
      end
    end

    # Get element or attribute by path
    # @return [Element, Attribute, nil]
    def [](*args)
      result = self

      args.flatten.each do |curname|
        next if result.nil?

        curname = curname.to_s

        if curname[0] == '@'
          result = result.all_attributes.find { |attr| attr.name == curname[1..-1] }
        else
          result = result.all_elements.find { |elem| elem.name == curname }
        end
      end

      result
    end

    # Search node by name in all available schemas and return its object
    # @param [Symbol] node_name
    # @param [String] name
    # @return [BaseObject, nil]
    def object_by_name(node_name, name)
      # get prefix and local name
      name_prefix = get_prefix(name)
      name_local  = strip_prefix(name)

      # do not search for built-in types
      return nil if schema.namespace_prefix == name_prefix

      # determine schema for namespace
      search_schema = schema_for_namespace(name_prefix)

      # find element in target schema
      result = search_schema.node.xpath("./xs:#{node_name}[@name=\"#{name_local}\"]", { 'xs' => XML_SCHEMA }).first

      result ? search_schema.node_to_object(result) : nil
    end

    # Get reader object for node
    # @param [Nokogiri::XML::Node]
    # @return [BaseObject]
    def node_to_object(node)
      # check object in cache first
      # TODO: проверить работу!
      return reader.object_cache[node.object_id] if reader.object_cache[node.object_id]

      klass = XML::CLASS_MAP[node.name]
      raise Error, "Object class not found for '#{node.name}'" unless klass

      reader.object_cache[node.object_id] = klass.new(options.merge(node: node, schema: schema))
    end

    # Get xml parent object
    # @return [BaseObject, nil]
    def parent
      node.respond_to?(:parent) && node.parent ? node_to_object(node.parent) : nil
    end

    # Get current schema object
    # @return [Schema]
    def schema
      options[:schema]
    end

    # Get child objects
    # @param [Symbol] name
    # @return [Array<BaseObject>]
    def map_children(name)
      nodes(name).map { |node| node_to_object(node) }
    end

    # Get child object
    # @param [Symbol] name
    # @return [BaseObject, nil]
    def map_child(name)
      map_children(name).first
    end

    # Strip namespace prefix from node name
    # @param [String, nil] name Name to strip from
    # @return [String, nil]
    def strip_prefix(name)
      name&.include?(':') ? name.split(':').last : name
    end

    # Get namespace prefix from node name
    # @param [String, nil] name Name to strip from
    # @return [String]
    def get_prefix(name)
      name&.include?(':') ? name.split(':').first : ''
    end

    # Return element documentation
    # @return [Array<String>]
    def documentation
      documentation_for(node)
    end

    # Return documentation for specified node
    # @param [Nokogiri::XML::Node] node
    # @return [Array<String>]
    def documentation_for(node)
      node.xpath('./xs:annotation/xs:documentation/text()', { 'xs' => XML_SCHEMA }).map(&:to_s).map(&:strip)
    end

    # Get all available elements on the current stack level
    # @return [Array<Element>]
    def all_elements(*)
      # exclude element that can not have elements
      return [] if NO_ELEMENTS_CONTAINER.include?(self.class.mapped_name)

      if is_a?(Referenced) && ref
        reference.all_elements
      else
        # map children recursive
        map_children(:*).map do |obj|
          if obj.is_a?(Element)
            obj
          else
            # get elements considering references
            (obj.is_a?(Referenced) && obj.ref ? obj.reference : obj).all_elements
          end
        end.flatten
      end
    end

    # Get all available attributes on the current stack level
    # @return [Array<Attribute>]
    def all_attributes(*)
      # exclude element that can not have elements
      return [] if NO_ATTRIBUTES_CONTAINER.include?(self.class.mapped_name)

      if is_a?(Referenced) && ref
        reference.all_attributes
      else
        # map children recursive
        map_children(:*).map do |obj|
          if obj.is_a?(Attribute)
            obj
          else
            # get attributes considering references
            (obj.is_a?(Referenced) && obj.ref ? obj.reference : obj).all_attributes
          end
        end.flatten
      end
    end

    # Get reader instance
    # @return [XML]
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
        name:    name,
        type:    type,
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
        value  = property[:resolve] ? property[:resolve].call(self) : node[property[:name].to_s]
        result = if value.nil?
                   # if object has reference - search property in referenced object
                   node['ref'] ? reference.send(method, *args) : property[:default]
                 else
                   case property[:type]
                   when :integer
                     property[:name] == :maxOccurs && value == 'unbounded' ? :unbounded : value.to_i
                   when :boolean
                     !!value
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
    # @return [Symbol]
    def self.mapped_name
      # @mapped_name ||= XML::CLASS_MAP.each { |k, v| return k.to_sym if v == self }
      @mapped_name ||= begin
        name    = self.name.split('::').last
        name[0] = name[0].downcase
        name.to_sym
      end
    end
  end
end
