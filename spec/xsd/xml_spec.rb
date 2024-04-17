# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::XML do
  subject(:reader) { described_class.open(file, :logger => spec_logger, resource_resolver: resource_resolver(file)) }

  context 'with ddex-v36 example files' do
    let(:file) { fixture_file(%w[ddex-v36 ddex-ern-v36.xsd], read: false) }

    it 'gives a schema_node namespaces' do
      node_namespaces = {
        'xmlns:xs'  => 'http://www.w3.org/2001/XMLSchema',
        'xmlns:ern' => 'http://ddex.net/xml/ern/36',
        'xmlns:avs' => 'http://ddex.net/xml/avs/avs'
      }

      expect(reader.schema.namespaces).to eq(node_namespaces)
    end

    it 'gives a schema reader' do
      expect(reader.schema.class).to eq XSD::Schema
    end

    it "gives an elements shortcut to its schema's shortcuts" do
      expect(reader.elements.map(&:name)).to eq reader.schema.collect_elements.map(&:name)
    end
  end

  context 'with ddex-mlc example files' do
    let(:file) { fixture_file(%w[ddex-mlc music-licensing-companies.xsd], read: false) }

    it 'reads referenced schemas which bind the xmlschema namespace to the root namespace instead of xs' do
      expect(reader['DeclarationOfSoundRecordingRightsClaimMessage'].collect_elements.first.name).to eq 'MessageHeader'
    end

    it 'returns <xs:any> in collect_elements list' do
      expect(reader['ManifestMessage']['FtpMessageHeader']['Signature']['KeyInfo']['X509Data'].collect_elements.last.name).to eq '#any'
    end
  end
end
