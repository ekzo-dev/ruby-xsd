# frozen_string_literal: true

module XSD
  # The appinfo element specifies information to be used by the application.
  # Parent elements: annotation
  # https://www.w3schools.com/xml/el_appinfo.asp
  class Appinfo < BaseObject
    # Optional. A URI reference that specifies the source of the application information
    # @!attribute source
    # @return [String]
    property :source, :string
  end
end
