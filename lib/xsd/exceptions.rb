# frozen_string_literal: true

module XSD
  class Error < StandardError
  end

  class ValidationError < Error
  end

  class ImportError < Error
  end
end
