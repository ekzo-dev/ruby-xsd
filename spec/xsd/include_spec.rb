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
end
