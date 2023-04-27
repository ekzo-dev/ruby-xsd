# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Extension do
  subject(:reader) { XSD::XML.new(file, :logger => spec_logger) }

  context 'with ddex-v32 example files' do
    subject(:extension) { element.complex_type.complex_content.extension }

    let(:file) { fixture_file(%w[ddex-v32 ern-main.xsd]) }
    let(:element) { reader[*%w[NewReleaseMessage ResourceList SoundRecording SoundRecordingDetailsByTerritory]] }

    describe '#linked_complex_type' do
      it 'finds linked complex typesfom imported schemas' do
        expect(extension.base).to eq 'ddexC:SoundRecordingDetailsByTerritory'

        # ToFix:
        # expect(extension.linked_complex_type.name).to eq 'SoundRecordingDetailsByTerritory'
        # expect(extension.linked_complex_type.schema).to be extension.schema.imports[1].reader.schema
      end
    end

    # ToFix:
    # describe '#ordered_elements' do
    #   it 'includes elements at the start from imported linked comlex type' do
    #     expected_elements = %w[TerritoryCode ExcludedTerritoryCode Title DisplayArtist ResourceContributor
    #                            IndirectResourceContributor RightsAgreementId LabelName RightsController RemasteredDate
    #                            OriginalResourceReleaseDate PLine CourtesyLine SequenceNumber HostSoundCarrier
    #                            MarketingComment Genre ParentalWarningType AvRating TechnicalSoundRecordingDetails
    #                            FulfillmentDate Keywords Synopsis]
    #
    #     expect(extension.ordered_elements.map(&:name)).to eq expected_elements
    #   end
    # end

    # ToFix:
    # describe "nested extensions" do
    #   it 'allows extensions to extend other extensions transparently' do
    #     el = reader['NewReleaseMessage']['ResourceList']['Video']['VideoDetailsByTerritory']
    #     expect(el.elements.map(&:name)).to eq %w[TerritoryCode ExcludedTerritoryCode Title DisplayArtist ResourceContributor IndirectResourceContributor RightsAgreementId LabelName RightsController RemasteredDate OriginalResourceReleaseDate PLine CourtesyLine SequenceNumber HostSoundCarrier MarketingComment Genre ParentalWarningType AvRating FulfillmentDate Keywords Synopsis CLine TechnicalVideoDetails Character]
    #   end
    # end
  end
end
