# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Extension do
  subject(:reader) { XSD::XML.open(file, :logger => spec_logger, resource_resolver: resource_resolver(file)) }

  context 'with ddex-v32 example files' do
    subject(:extension) { element.complex_type.complex_content.extension }

    let(:file) { fixture_file(%w[ddex-v32 ern-main.xsd], read: false) }
    let(:element) { reader[*%w[NewReleaseMessage ResourceList SoundRecording SoundRecordingDetailsByTerritory]] }

    describe '#linked_complex_type' do
      it 'finds linked complex types from imported schemas' do
        expect(extension.base).to eq 'ddexC:SoundRecordingDetailsByTerritory'

        # ToFix:
        # expect(extension.complex_type.name).to eq 'SoundRecordingDetailsByTerritory'
        # expect(extension.linked_complex_type.schema).to be extension.schema.imports[1].reader.schema
      end
    end

    describe '#ordered_elements' do
      it 'includes elements at the start from imported linked comlex type' do
        expected_elements = %w[TerritoryCode ExcludedTerritoryCode Title DisplayArtist ResourceContributor
                               IndirectResourceContributor RightsAgreementId LabelName RightsController RemasteredDate
                               OriginalResourceReleaseDate PLine CourtesyLine SequenceNumber HostSoundCarrier
                               MarketingComment Genre ParentalWarningType AvRating TechnicalSoundRecordingDetails
                               FulfillmentDate Keywords Synopsis]

        expect(extension.collect_elements.map(&:name)).to eq expected_elements
      end
    end

    describe 'nested extensions' do
      it 'allows extensions to extend other extensions transparently' do
        el = reader['NewReleaseMessage']['ResourceList']['Video']['VideoDetailsByTerritory']
        expected = %w[TerritoryCode ExcludedTerritoryCode Title DisplayArtist ResourceContributor IndirectResourceContributor RightsAgreementId LabelName RightsController RemasteredDate OriginalResourceReleaseDate PLine CourtesyLine SequenceNumber HostSoundCarrier MarketingComment Genre ParentalWarningType AvRating FulfillmentDate Keywords Synopsis CLine TechnicalVideoDetails Character]

        expect(el.collect_elements.map(&:name)).to eq expected
      end
    end
  end

  context 'with kitchen-sink example files' do
    subject(:reader) { XSD::XML.open(file, logger: spec_logger) }

    let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }
    let(:extension) { reader['Catalog']['Item'].complex_type.complex_content.extension }

    describe '#base' do
      it 'gives the base type name and resolves it' do
        expect(extension.base).to eq 'ks:AbstractItemType'
        expect(extension.base_complex_type.name).to eq 'AbstractItemType'
        expect(extension.base_simple_type).to be_nil
      end
    end

    describe '#collect_elements' do
      it 'puts the base type elements first' do
        expect(extension.collect_elements.map(&:name))
          .to eq %w[Title Description Size Measure Tags Comment Note Link #any]
      end

      it 'omits the base type elements when asked to' do
        expect(extension.collect_elements(false).map(&:name)).to eq %w[Size Measure Tags Comment Note Link #any]
      end
    end

    describe '#collect_attributes' do
      it 'puts the base type attributes first' do
        expect(extension.collect_attributes.map(&:name)).to eq %w[lang revision sku #anyAttribute]
      end

      it 'omits the base type attributes when asked to' do
        expect(extension.collect_attributes(false).map(&:name)).to eq %w[sku #anyAttribute]
      end
    end

    describe 'simpleContent extension' do
      subject(:simple) { reader['Catalog']['Item']['Measure'].complex_type.simple_content.extension }

      it 'resolves a simple base type' do
        expect(simple.base).to eq 'ks:CountType'
        expect(simple.base_simple_type.name).to eq 'CountType'
        expect(simple.base_complex_type).to be_nil
      end

      it 'declares the attributes added on top of the simple content' do
        expect(simple.collect_attributes.map(&:name)).to eq %w[unit]
        expect(simple.collect_elements).to eq []
      end
    end
  end
end
