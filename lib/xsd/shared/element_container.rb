# frozen_string_literal: true

module XSD
  module ElementContainer
    # Nested elements
    # @!attribute elements
    # @return [Array<Element>]
    def self.included(obj)
      obj.child :elements, [:element]
    end
  end
end
