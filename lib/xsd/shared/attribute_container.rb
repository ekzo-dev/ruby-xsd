# frozen_string_literal: true

module XSD
  module AttributeContainer
    # Nested attributes
    # @!attribute attributes
    # @return Array<Attribute>

    # Nested attribute groups
    # @!attribute attribute_groups
    # @return Array<AttributeGroup>
    def self.included(obj)
      obj.child :attributes, [:attribute]
      obj.child :attribute_groups, [:attributeGroup]
    end
  end
end
