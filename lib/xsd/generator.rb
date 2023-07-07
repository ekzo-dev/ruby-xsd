# frozen_string_literal: true

require 'builder'

module XSD
  module Generator
    # Generate XML from provided data
    # @param [Hash] data
    # @param [String, Array<String>] element
    # @param [Builder::XmlMarkup] builder
    # @return Builder::XmlMarkup
    def generate(data, element = nil, builder = nil)
      # find root element
      root = find_root_element(element)

      # create builder
      builder ||= default_builder

      # build element tree
      @namespace_index = 0
      build_element(builder, root, data)

      builder
    end

    private

    # Build element tree
    # @param [Builder::XmlMarkup] xml
    # @param [Element] element
    # @param [Hash] data
    # @param [Hash] namespaces
    def build_element(xml, element, data, namespaces = {})
      # get item data
      elements         = (element.abstract ? [] : [element]) + element.substitution_elements
      provided_element = elements.find { |elem| !data[elem.name].nil? }

      if element.required? && provided_element.nil?
        raise Error, "Element #{element.name} is required, but no data in provided for it"
      end
      return unless provided_element

      element = provided_element
      data    = data[element.name]

      # handle repeated items
      if element.multiple_allowed?
        unless data.is_a?(Array)
          raise Error, "Element #{element.name} is allowed to occur multiple times, but non-array is provided"
        end
      else
        if data.is_a?(Array)
          raise Error, "Element #{element.name} is not allowed to occur multiple times, but an array is provided"
        end

        data = [data]
      end

      # configure namespaces
      # TODO: попытаться использовать collect_namespaces?
      attributes = {}
      all_attributes = element.all_attributes
      if element.complex?
        all_elements = element.all_elements

        # get namespaces for current element and it's children
        prefix = nil
        [*all_elements, element].each do |elem|
          prefix = get_namespace_prefix(elem, attributes, namespaces)
        end
      else
        prefix = get_namespace_prefix(element, attributes, namespaces)
      end

      # iterate through each item
      data.each do |item|
        # prepare attributes
        all_attributes.each do |attribute|
          value = item["@#{attribute.name}"]
          if value
            attributes[attribute.name] = value
          else
            attributes.delete(attribute.name)
          end
        end

        # generate element
        if element.complex?
          # generate tag recursively
          xml.tag!("#{prefix}:#{element.name}", attributes) do
            all_elements.each do |elem|
              build_element(xml, elem, item, namespaces.dup)
            end
          end
        else
          value  = item.is_a?(Hash) ? item['#text'] : item
          xml.tag!("#{prefix}:#{element.name}", attributes, (value == '' ? nil : value))
        end
      end
    end

    # Get namespace prefix for element
    # @param [Element] element
    # @param [Hash] attributes
    # @param [Hash] namespaces
    # @return String
    def get_namespace_prefix(element, attributes, namespaces)
      namespace = (element.referenced? ? element.reference : element).target_namespace
      prefix    = namespaces.key(namespace)
      unless prefix
        prefix             = "tns#{@namespace_index += 1}"
        namespaces[prefix] = attributes["xmlns:#{prefix}"] = namespace
      end

      prefix
    end

    # Find root element with provided lookup
    # @param [String, Array<String>, nil] lookup
    def find_root_element(lookup)
      if lookup
        element = schema[*lookup]
        raise Error, "Cant find start element #{lookup}" unless element.is_a?(Element)

        element
      else
        raise Error, 'XSD contains more that one root element. Please, specify starting element' if elements.size > 1

        elements.first
      end
    end

    def default_builder
      Builder::XmlMarkup.new
    end
  end
end
