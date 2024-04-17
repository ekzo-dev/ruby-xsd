# frozen_string_literal: true

module XSD
  module MinMaxOccurs
    # Optional. Specifies the minimum number of times the choice element can occur in the parent the element.
    # The value can be any number >= 0. Default value is 1
    # @!attribute min_occurs
    # @return Integer

    # Optional. Specifies the maximum number of times the choice element can occur in the parent element.
    # The value can be any number >= 0, or if you want to set no limit on the maximum number, use the value "unbounded".
    # Default value is 1
    # @!attribute max_occurs
    # @return Integer, Symbol
    def self.included(obj)
      obj.property :minOccurs, :integer, default: 1
      obj.property :maxOccurs, :integer, default: 1
    end

    # Compute actual max_occurs accounting parents
    # @return Integer, Symbol
    def computed_max_occurs
      @computed_max_occurs ||= if parent.is_a?(MinMaxOccurs)
                                 if max_occurs == :unbounded || parent.computed_max_occurs == :unbounded
                                   :unbounded
                                 else
                                   [max_occurs, parent.computed_max_occurs].max
                                 end
                               else
                                 max_occurs
                               end
    end

    # Compute actual min_occurs accounting parents
    # @return Integer
    def computed_min_occurs
      @computed_min_occurs ||= if parent.is_a?(Choice)
                                 0
                               elsif parent.is_a?(MinMaxOccurs)
                                 [min_occurs, parent.computed_min_occurs].min
                               else
                                 min_occurs
                               end
    end

    # Determine if element may occur multiple times
    # @return Boolean
    def multiple_allowed?
      computed_max_occurs == :unbounded || computed_max_occurs > 1
    end
  end
end
