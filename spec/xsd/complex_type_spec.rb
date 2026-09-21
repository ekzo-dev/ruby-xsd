# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::ComplexType do
  subject(:reader) { XSD::XML.open(file, logger: spec_logger, resource_resolver: resource_resolver(file)) }

  context 'with gkh example file' do
    subject(:element) { reader['importWorkingListRequest', 'Signature', 'SignedInfo', 'CanonicalizationMethod'] }

    let(:file) { fixture_file(%w[gkh hcs-services-types.xsd], read: false) }

    describe '#mixed' do
      it 'reads mixed property as boolean' do
        expect(element.complex_type.mixed).to be(true)
      end
    end
  end

  context 'with XSDShemas example file' do
    subject(:element) { reader['VehicleMassMeasure'] }

    let(:file) { fixture_file(%w[XSDShemas EPTSAllData_v1.0.0.xsd], read: false) }

    describe '#data_type' do
      it 'reads data_type from simple_content' do
        expect(element.complex_type.data_type).to eq('decimal')
      end
    end
  end

  context 'with kitchen-sink example files' do
    subject(:reader) { XSD::XML.open(file, logger: spec_logger) }

    let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }

    def complex_type(name)
      reader.complex_types.find { |type| type.name == name }
    end

    describe '#linked?' do
      it 'is true for a named (global) type' do
        expect(complex_type('ItemType')).to be_linked
      end

      it 'is false for an anonymous nested type' do
        expect(reader['Catalog'].complex_type).not_to be_linked
      end
    end

    describe '#abstract' do
      it 'reads the attribute as a boolean' do
        expect(complex_type('AbstractItemType').abstract).to be true
        expect(complex_type('ItemType').abstract).to be false
      end
    end

    describe '#complex_content?' do
      it 'is a boolean, true for a complexContent derivation' do
        expect(complex_type('ItemType').complex_content?).to be true
      end

      it 'is a boolean, true for a bare particle' do
        expect(complex_type('MixedTextType').complex_content?).to be true
      end

      it 'is false for a simpleContent type' do
        expect(complex_type('MeasureType').complex_content?).to be false
      end
    end

    describe '#simple_content?' do
      it 'is true only for a simpleContent type' do
        expect(complex_type('MeasureType').simple_content?).to be true
        expect(complex_type('ItemType').simple_content?).to be false
      end
    end

    describe '#mixed_content?' do
      it 'is true when declared on the type' do
        expect(complex_type('MixedTextType').mixed_content?).to be true
      end

      it 'is inherited from the base type of an extension' do
        expect(complex_type('DerivedMixedType').mixed).to be false
        expect(complex_type('DerivedMixedType').mixed_content?).to be true
      end

      it 'is false for a type that is neither mixed nor derived from a mixed one' do
        expect(complex_type('ItemType').mixed_content?).to be false
      end

      it 'is false rather than an error for a complexContent without a derivation' do
        type = XSD::XML.new(logger: spec_logger).add_schema_xml(<<~XML).complex_types.first
          <?xml version="1.0"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:complexType name="Broken"><xs:complexContent/></xs:complexType>
          </xs:schema>
        XML

        expect(type.mixed_content?).to be false
      end
    end

    describe '#data_type' do
      it 'is nil without simple content' do
        expect(complex_type('ItemType').data_type).to be_nil
      end

      it 'resolves the base of a simpleContent extension' do
        expect(complex_type('MeasureType').data_type).to eq 'decimal'
      end

      it 'is nil rather than an error for a simpleContent without a derivation' do
        type = XSD::XML.new(logger: spec_logger).add_schema_xml(<<~XML).complex_types.first
          <?xml version="1.0"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:complexType name="Broken"><xs:simpleContent/></xs:complexType>
          </xs:schema>
        XML

        expect(type.data_type).to be_nil
      end
    end

    describe 'particles' do
      it 'exposes only the particle the type actually uses' do
        type = complex_type('MixedTextType')

        expect(type.sequence).to be_a XSD::Sequence
        expect(type.choice).to be_nil
        expect(type.all).to be_nil
        expect(type.group).to be_nil
      end
    end
  end
end
