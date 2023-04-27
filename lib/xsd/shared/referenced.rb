# frozen_string_literal: true

module XSD
  module Referenced
    # Optional. Specifies a reference to a named attribute. Name and ref attributes cannot both be present.
    # If ref is present, simpleType element, form, and type cannot be present
    # @!attribute ref
    # @return [String]

    # Reference object
    # @!attribute reference
    # @return [BaseObject]
    def self.included(obj)
      obj.property :ref, :string
      obj.link :reference, obj.mapped_name, property: :ref
    end

    # Is object referenced?
    # @return [Boolean]
    def referenced?
      !ref.nil?
    end
  end
end
