# frozen_string_literal: true

module XSD
  # A definition's data type follows from the schema, which does not change once read: it is worked out on first use
  # and kept. Reading XML casts every value by it, so it is asked for once per value otherwise.
  module CachedDataType
    def data_type
      return @data_type if defined?(@data_type)

      @data_type = super
    end
  end
end
