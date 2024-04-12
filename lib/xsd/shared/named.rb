# frozen_string_literal: true

module XSD
  module Named
    # Get definition namespace
    # @return String
    def namespace
      is_referenced = respond_to?(:referenced?)
      is_referenced && referenced? ? reference.schema.target_namespace : schema.target_namespace
    end

    # Get absolute definition name
    # @return String
    def absolute_name
      name ? "{#{namespace}}#{name}" : nil
    end
  end
end
