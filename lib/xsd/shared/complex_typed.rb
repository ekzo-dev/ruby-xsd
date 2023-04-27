# frozen_string_literal: true

module XSD
  # Provides object an ability to have complex type (nested or linked)
  module ComplexTyped
    # Child/linked complex type
    # @!attribute complex_type
    # @return [ComplexType, nil]
    def self.included(obj)
      obj.child :complex_type, :complexType
      obj.link :complex_type, :complexType, property: obj::TYPE_PROPERTY
    end

    # Get all available elements on the current stack level or linked type elements
    # @param [Boolean] linked_type
    # @return [Array<Element>]
    def all_elements(linked_type = true)
      (linked_type && complex_type&.linked? ? complex_type.all_elements : super)
    end

    # Get all available attributes on the current stack level or linked type attributes
    # @param [Boolean] linked_type
    # @return [Array<Attribute>]
    def all_attributes(linked_type = true)
      (linked_type && complex_type&.linked? ? complex_type.all_attributes : super)
    end
  end
end
