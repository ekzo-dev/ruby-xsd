# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Import do
  subject(:reader) { XSD::XML.open(file, logger: spec_logger, resource_resolver: resource_resolver(file)) }

  context 'with ddex-v36 example files' do
    subject(:import) { reader.schema.imports[0] }

    let(:file) { fixture_file(%w[ddex-v36 ddex-ern-v36.xsd], read: false) }

    it 'gives a namespace' do
      expect(import.namespace).to eq 'http://ddex.net/xml/avs/avs'
    end

    it 'gives a schema location' do
      expect(import.schema_location).to eq 'avs.xsd'
    end

    it 'gives a schema for the external XSD' do
      expect(import.imported_schema.class).to eq XSD::Schema
    end

    it 'downloads related xsd files' do
      s1 = XSD::XML.open(fixture_file(%w[ddex-v36 avs.xsd], read: false), logger: spec_logger, resource_resolver: resource_resolver(file)).schema
      s2 = import.imported_schema

      expect(s1.collect_elements.map(&:name)).to eq s2.collect_elements.map(&:name)
      expect(s1.simple_types.map(&:name)).to eq s2.simple_types.map(&:name)
    end
  end

  context 'with a broken import' do
    let(:importing_xsd) do
      <<~XML
        <?xml version="1.0"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:other="urn:other"
                   targetNamespace="urn:main">
          <xs:import namespace="urn:other"/>
          <xs:element name="Root" type="other:Thing"/>
        </xs:schema>
      XML
    end

    it 'asks the caller to register the schema when no location is given' do
      reader = XSD::XML.new(logger: spec_logger)
      reader.add_schema_xml(importing_xsd)

      expect { reader.schema.imports[0].imported_schema }
        .to raise_error(XSD::ImportError, /Schema location not provided for namespace 'urn:other'/)
    end

    it 'uses a schema registered for the namespace instead of loading one' do
      reader = XSD::XML.new(logger: spec_logger)
      reader.add_schema_xml(importing_xsd)
      imported = reader.add_schema_xml(<<~XML)
        <?xml version="1.0"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" targetNamespace="urn:other">
          <xs:complexType name="Thing"><xs:sequence/></xs:complexType>
        </xs:schema>
      XML

      expect(reader.schema.imports[0].imported_schema).to be imported
      expect(reader['Root'].complex_type.name).to eq 'Thing'
    end

    it 'rejects a schema whose target namespace does not match the import' do
      reader = XSD::XML.new(logger: spec_logger, resource_resolver: proc { <<~XML })
        <?xml version="1.0"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" targetNamespace="urn:surprise"/>
      XML
      reader.add_schema_xml(importing_xsd.sub('namespace="urn:other"', 'namespace="urn:other" schemaLocation="o.xsd"'))

      expect { reader.schema.imports[0].imported_schema }
        .to raise_error(XSD::ImportError, /'urn:other' does not match imported schema targetNamespace 'urn:surprise'/)
    end
  end
end
