# frozen_string_literal: true

module XSD
  # Used by extension and restriction elements
  module Based
    # Required. Specifies the name of a built-in data type, a simpleType element, or a complexType element
    # @!attribute base
    # @return String

    # Base complexType
    # @!attribute base_complex_type
    # @return ComplexType, nil

    # Base simpleType
    # @!attribute base_simple_type
    # @return SimpleType, nil
    def self.included(obj)
      obj.property :base, :string, required: true
      obj.link :base_complex_type, :complexType, property: :base
      obj.link :base_simple_type, :simpleType, property: :base
    end

    # Get all available elements on the current stack level, optionally including base type elements
    # @param [Boolean] include_base
    # @return Array<Element>
    def all_elements(include_base = true)
      (include_base && base_complex_type ? base_complex_type.all_elements : []) + super
    end

    # Get all available attributes on the current stack level, optionally including base type attributes
    # @param [Boolean] include_base
    # @return Array<Attribute>
    def all_attributes(include_base = true)
      (include_base && base_complex_type ? base_complex_type.all_attributes : []) + super
    end
  end
end
