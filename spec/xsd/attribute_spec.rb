# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Attribute do
  let(:reader) { XSD::XML.new(file, :logger => spec_logger) }

  context 'with ddex-v36 example files' do
    let(:file) { fixture_file(%w[ddex-v36 ddex-ern-v36.xsd]) }
    let(:attribute) { reader['NewReleaseMessage']['@MessageSchemaVersionId'] }

    it 'gives a name' do
      expect(attribute.name).to eq 'MessageSchemaVersionId'
    end

    it 'gives a type information' do
      expect(attribute.type).to eq 'xs:string'

      # ToFix: type_name
      # expect(attribute.type_name).to eq 'string'

      # ToFix: type_namespace
      # expect(attribute.type_namespace).to eq 'xs'
    end

    it 'gives a boolean required indication' do
      expect(attribute.required?).to be true
    end
  end
end
