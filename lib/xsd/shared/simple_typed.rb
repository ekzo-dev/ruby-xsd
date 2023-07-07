# frozen_string_literal: true

module XSD
  # Provides object an ability to have simple type (nested or linked)
  module SimpleTyped
    # Get child/linked simple type
    # @!attribute simple_type
    # @return SimpleType, nil
    def self.included(obj)
      obj.child :simple_type, :simpleType
      obj.link :simple_type, :simpleType, property: obj::TYPE_PROPERTY
    end
  end
end
