# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Include do
  subject(:reader) { XSD::XML.open(file, logger: spec_logger, resource_resolver: resource_resolver(file)) }

  context 'with gkn example files' do
    subject(:include) { reader.schema.includes[0] }

    let(:file) { fixture_file(%w[gkn CR_ZC_REQ_Reqest.xsd], read: false) }

    it 'gives a schema location' do
      expect(include.schema_location).to eq 'dRegionsRF.xsd'
    end

    it 'gives a schema for the external XSD' do
      expect(include.imported_schema.class).to eq XSD::Schema
    end

    it 'downloads related xsd files' do
      s1 = XSD::XML.open(fixture_file(%w[gkn dRegionsRF.xsd], read: false), logger: spec_logger, resource_resolver: resource_resolver(file)).schema
      s2 = include.imported_schema

      expect(s1.simple_types.map(&:name)).to eq s2.simple_types.map(&:name)
    end

    it 'finds linked types in included schemas' do
      el = reader['Requests_GZK_Realty']['Request_GZK_Realty']['Object']['Parcels']['Parcel']['Location']['Region']
      expect(el.simple_type.name).to eq 'dRegionsRF'
    end
  end

  context 'with schemas that are reachable from several places' do
    subject(:reader) { XSD::XML.open(file, logger: spec_logger, resource_resolver: resource_resolver(file)) }

    context 'with gkn example files, which include the same schemas from several places' do
      let(:file) { fixture_file(%w[gkn CR_ZC_REQ_Reqest.xsd], read: false) }

      it 'reads each distinct location only once' do
        locations = []
        reader = XSD::XML.open(file, logger: spec_logger, resource_resolver: proc { |location, _|
          locations << location
          resource_resolver(file).call(location, nil)
        })
        reader.simple_types
        reader.schema.collect_elements.each(&:collect_elements)

        expect(locations).to eq locations.uniq
      end

      it 'keeps one schema object per location' do
        reader.simple_types

        expect(reader.schemas.size).to eq reader.schemas.uniq.size
        expect(reader.schemas.size).to eq 24
      end
    end
  end

  context 'with a broken include' do
    def reader_for(included_xsd)
      reader = XSD::XML.new(logger: spec_logger, resource_resolver: proc { included_xsd })
      reader.add_schema_xml(<<~XML)
        <?xml version="1.0"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:main="urn:main" targetNamespace="urn:main">
          <xs:include schemaLocation="part.xsd"/>
          <xs:element name="Root" type="main:Thing"/>
        </xs:schema>
      XML
      reader
    end

    it 'accepts an included schema with the same target namespace' do
      reader = reader_for(<<~XML)
        <?xml version="1.0"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" targetNamespace="urn:main">
          <xs:complexType name="Thing"><xs:sequence/></xs:complexType>
        </xs:schema>
      XML

      expect(reader['Root'].complex_type.name).to eq 'Thing'
    end

    it 'accepts a chameleon include, which has no target namespace of its own' do
      reader = reader_for(<<~XML)
        <?xml version="1.0"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
          <xs:complexType name="Thing"><xs:sequence/></xs:complexType>
        </xs:schema>
      XML

      expect(reader.schema.includes[0].imported_schema.target_namespace).to be_nil
      expect(reader['Root'].complex_type.name).to eq 'Thing'
    end

    it 'rejects an included schema that targets a different namespace' do
      reader = reader_for(<<~XML)
        <?xml version="1.0"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" targetNamespace="urn:surprise"/>
      XML

      expect { reader.schema.includes[0].imported_schema }
        .to raise_error(XSD::ImportError, /'urn:main' does not match included schema targetNamespace 'urn:surprise'/)
    end

    it 'requires a schema location' do
      reader = XSD::XML.new(logger: spec_logger)
      reader.add_schema_xml(<<~XML)
        <?xml version="1.0"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" targetNamespace="urn:main"><xs:include/></xs:schema>
      XML

      expect { reader.schema.includes[0].imported_schema }
        .to raise_error(XSD::ImportError, /Schema location not provided for include/)
    end
  end

  context 'with schemas that include each other' do
    let(:files) do
      {
        'a.xsd' => <<~XML,
          <?xml version="1.0"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" targetNamespace="urn:cycle">
            <xs:include schemaLocation="b.xsd"/>
            <xs:simpleType name="A"><xs:restriction base="xs:string"/></xs:simpleType>
          </xs:schema>
        XML
        'b.xsd' => <<~XML
          <?xml version="1.0"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" targetNamespace="urn:cycle">
            <xs:include schemaLocation="a.xsd"/>
            <xs:simpleType name="B"><xs:restriction base="xs:string"/></xs:simpleType>
          </xs:schema>
        XML
      }
    end

    let(:reader) do
      reader = XSD::XML.new(logger: spec_logger, resource_resolver: proc { |location, _| files[location] })
      reader.add_schema_xml(files['a.xsd'], location: 'a.xsd')
      reader
    end

    it 'walks the cycle once instead of repeating the definitions it already saw' do
      expect(reader.schema.simple_types.map(&:name)).to eq %w[A B]
    end

    it 'reuses the schema registered for the location it was added under' do
      reader.simple_types

      expect(reader.schemas.size).to eq 2
      expect(reader.schema.includes[0].imported_schema.includes[0].imported_schema).to be reader.schema
    end
  end
end
