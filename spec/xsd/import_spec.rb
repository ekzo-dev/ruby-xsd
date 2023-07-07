# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Import do
  subject(:reader) { XSD::XML.open(file, logger: spec_logger, resource_resolver: resource_resolver(file)) }

  context 'with ddex-v36 example files' do
    subject(:import) { reader.schema.imports[0] }

    let(:file) { fixture_file(%w[ddex-v36 ddex-ern-v36.xsd], read: false) }

    it 'gives the namespace' do
      expect(import.namespace).to eq 'http://ddex.net/xml/avs/avs'
    end

    it 'gives the schema location' do
      expect(import.schema_location).to eq 'avs.xsd'
    end

    it 'gives a reader for the external XSD' do
      expect(import.imported_schema.class).to eq XSD::Schema
    end

    it 'downloads related xsd files' do
      s1 = XSD::XML.open(fixture_file(%w[ddex-v36 avs.xsd], read: false), logger: spec_logger, resource_resolver: resource_resolver(file)).schema
      s2 = import.imported_schema

      expect(s1.collect_elements.map(&:name)).to eq s2.collect_elements.map(&:name)
      expect(s1.simple_types.map(&:name)).to eq s2.simple_types.map(&:name)
    end
  end
end
