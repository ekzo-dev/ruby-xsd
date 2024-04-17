# frozen_string_literal: true

module XSD
  # The restriction element defines restrictions on a simpleType, simpleContent, or complexContent definition.
  # Parent elements: simpleType, simpleContent, complexContent
  # https://www.w3schools.com/xml/el_restriction.asp
  class Restriction < BaseObject
    TYPE_PROPERTY = nil

    include Based
    include SimpleTyped
    include AttributeContainer

    FACET_ELEMENTS = %w[
      minExclusive minInclusive maxExclusive maxInclusive totalDigits
      fractionDigits length minLength maxLength enumeration whiteSpace pattern
    ].freeze

    # Nested group
    # @!attribute group
    # @return Group
    child :group, :group

    # Nested all
    # @!attribute all
    # @return All
    child :all, :all

    # Nested choice
    # @!attribute choice
    # @return Choice
    child :choice, :choice

    # Nested sequence
    # @!attribute sequence
    # @return Sequence
    child :sequence, :sequence

    # Get restriction facets
    # @return Hash
    def facets
      nodes.inject({}) do |hash, node|
        if FACET_ELEMENTS.include?(node.name)
          key   = node.name
          value = node['value']

          if key == 'enumeration'
            hash[key]        ||= {}
            hash[key][value] = documentation_for(node)
          elsif key == 'pattern'
            hash[key] ||= []
            hash[key].push(value)
          else
            hash[key] = value
          end
        end
        hash
      end
    end

    # Get all available elements on the current stack level, optionally including base type elements
    # @param [Boolean] include_base
    # @return Array<Element>
    def collect_elements(include_base = false)
      # Don't include elements from base by default, that will lead to element duplicates because
      # elements in complex restriction MUST be all listen in restricting type
      super(include_base)
    end

    # Get all available attributes on the current stack level, optionally including base type attributes
    # @param [Boolean] include_base
    # @return Array<Attribute>
    def collect_attributes(include_base = true)
      result = super(include_base)
      # Filter restricted attributes to avoid duplicates from restricting and restricted type
      result.inject({}) { |hash, item| hash[item.name] = item; hash }.values if include_base
    end
  end
end
