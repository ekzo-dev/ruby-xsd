# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Attribute do
  let(:reader) { XSD::XML.open(file, :logger => spec_logger, resource_resolver: resource_resolver(file)) }

  context 'with ddex-v36 example files' do
    let(:file) { fixture_file(%w[ddex-v36 ddex-ern-v36.xsd], read: false) }
    let(:attribute) { reader['NewReleaseMessage']['@MessageSchemaVersionId'] }

    it 'gives a name' do
      expect(attribute.name).to eq 'MessageSchemaVersionId'
    end

    it 'gives a type information' do
      expect(attribute.type).to eq 'xs:string'
    end

    it 'gives a boolean required indication' do
      expect(attribute.required?).to be true
    end
  end

  context 'with kitchen-sink example files' do
    let(:reader) { XSD::XML.open(file, logger: spec_logger) }
    let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }
    let(:item) { reader['Catalog']['Item'] }

    def attribute(name)
      item.collect_attributes.find { |attr| attr.name == name }
    end

    describe '#use' do
      it 'defaults to optional' do
        expect(attribute('lang').use).to eq 'optional'
        expect(attribute('lang')).to be_optional
        expect(attribute('lang')).not_to be_required
      end

      it 'recognises a required attribute' do
        expect(attribute('sku')).to be_required
        expect(attribute('sku')).not_to be_optional
      end

      it 'recognises a prohibited attribute' do
        restricted = reader['Catalog']['RestrictedItem'].collect_attributes.find { |a| a.name == 'revision' }

        expect(restricted).to be_prohibited
        expect(restricted).not_to be_optional
      end
    end

    describe '#default and #fixed' do
      it 'gives the declared default' do
        expect(attribute('lang').default).to eq 'en'
        expect(attribute('lang').fixed).to be_nil
      end

      it 'gives the declared fixed value' do
        expect(attribute('revision').fixed).to eq '1.0'
        expect(attribute('revision').default).to be_nil
      end
    end

    describe '#form' do
      it 'defaults to the attributeFormDefault of the schema' do
        expect(attribute('sku').form).to eq 'unqualified'
      end
    end

    describe '#data_type' do
      it 'strips the prefix off a built-in type' do
        expect(attribute('sku').type).to eq 'xs:string'
        expect(attribute('sku').data_type).to eq 'string'
      end

      it 'resolves a linked simple type' do
        size = reader['Catalog']['@size']

        expect(size.simple_type.name).to eq 'SizeOrCountType'
        expect(size.data_type).to eq %w[string int]
      end

      it 'is nil for an attribute without a type' do
        restricted = reader['Catalog']['RestrictedItem'].collect_attributes.find { |a| a.name == 'revision' }

        expect(restricted.data_type).to be_nil
      end
    end

    describe '#absolute_name' do
      it 'combines the namespace of the declaring schema and the name' do
        expect(attribute('sku').absolute_name).to eq '{urn:kitchen-sink}sku'
      end
    end

    it 'contributes no nested elements or attributes' do
      expect(attribute('sku').collect_elements).to eq []
      expect(attribute('sku').collect_attributes).to eq []
    end
  end
end
