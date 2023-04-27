# frozen_string_literal: true

require 'rest-client'

module XSD
  # The import element is used to add multiple schemas with different target namespace to a document.
  # Parent elements: schema
  # https://www.w3schools.com/xml/el_import.asp
  class Import < BaseObject
    # Optional. Specifies the URI of the namespace to import
    # @!attribute namespace
    # @return [String, nil]
    property :namespace, :string

    # Optional. Specifies the URI to the schema for the imported namespace
    # @!attribute schema_location
    # @return [String, nil]
    property :schemaLocation, :string

    # Get imported reader
    # @return [XSD:XML]
    def imported_reader
      return @imported_reader if @imported_reader

      xml = if reader.imported_xsd[namespace]
              # check in imported xsd by namespace
              reader.imported_xsd[namespace]
            elsif schema_location =~ /^https?:/
              # check http(s) schema location
              download_uri(schema_location)
            elsif (path = local_path)
              # check local relative path
              path
            elsif namespace =~ /^https?:/
              # check http(s) namespace
              # TODO: investigate spec conformance
              download_uri(namespace.gsub(/#{File.basename(schema_location, '.*')}$/, '').to_s + schema_location)
            else
              raise ImportError, "Failed to locate import '#{schema_location}' for namespace '#{namespace}'"
            end

      # TODO: pass all provided options
      @imported_reader = XSD::XML.new(xml, imported_xsd: reader.imported_xsd, logger: reader.logger)
    end

    def local_path
      return unless reader.xsd.is_a?(Pathname)

      path = reader.xsd.dirname.join(schema_location)
      path.file? ? path : nil
    end

    private

    def download_uri(uri)
      reader.logger.debug(XSD) { "Downloading import schema for namespace '#{namespace}' from '#{uri}'" }

      begin
        response = RestClient.get(uri)
      rescue RestClient::Exception => e
        raise ImportError, e.message
      end

      response.body
    end
  end
end
