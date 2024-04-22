# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Element do
  subject(:reader) { XSD::XML.open(file, :logger => spec_logger, resource_resolver: resource_resolver(file)) }

  context 'with ddex-v36 example files' do
    subject(:element) { reader.elements[0] }

    let(:file) { fixture_file(%w[ddex-v36 ddex-ern-v36.xsd], read: false) }

    it "gives an element's child" do
      expect(reader['NewReleaseMessage']).to eq reader.elements[0]
    end

    it "gives the element's name" do
      expect(element.name).to eq 'NewReleaseMessage'
    end

    it 'returns nil when attribute available' do
      expect(element.ref).to be_nil
    end

    it 'gives the type of an element' do
      expect(reader[*%w[NewReleaseMessage MessageHeader]].type).to eq 'ern:MessageHeader'
    end

    it 'gives a complex type reader' do
      expect(element.complex_type.class).to eq XSD::ComplexType
    end

    it 'gives child elements in the right order' do
      expected_elements = %w[CommercialModelType Usage AllDealsCancelled TakeDown TerritoryCode ExcludedTerritoryCode
                             DistributionChannel ExcludedDistributionChannel PriceInformation IsPromotional
                             PromotionalCode ValidityPeriod ConsumerRentalPeriod PreOrderReleaseDate
                             ReleaseDisplayStartDate TrackListingPreviewStartDate CoverArtPreviewStartDate
                             ClipPreviewStartDate PreOrderPreviewDate IsExclusive RelatedReleaseOfferSet PhysicalReturns
                             NumberOfProductsPerCarton RightsClaimPolicy WebPolicy]

      expect(reader['NewReleaseMessage']['DealList']['ReleaseDeal']['Deal']['DealTerms']
               .collect_elements.map(&:name)).to eq expected_elements
    end

    it 'includes elements within a choice node' do
      el = element.collect_elements[3]
      expect(el.name).to eq 'CatalogTransfer'
      elements_with = %w[CatalogTransferCompleted EffectiveTransferDate CatalogReleaseReferenceList TerritoryCode ExcludedTerritoryCode TransferringFrom TransferringTo]
      expect(el.complex_type.collect_elements.map(&:name)).to eq elements_with
    end

    it 'gives child elements defined within a complex type' do
      expected_elements = %w[MessageHeader UpdateIndicator IsBackfill CatalogTransfer WorkList
                             CueSheetList ResourceList CollectionList ReleaseList DealList]

      expect(element.collect_elements.map(&:name)).to eq expected_elements
    end

    it 'gives attributes defined in a complexType' do
      expected_attributes = %w[MessageSchemaVersionId BusinessProfileVersionId
                               ReleaseProfileVersionId LanguageAndScriptCode]

      expect(element.collect_attributes.map(&:name)).to eq expected_attributes
      expect(element.complex_type.attributes.map(&:name)).to eq expected_attributes
    end

    it 'gives attributes defined in a simpleContent extension' do
      element_result = element['ResourceList']['SoundRecording']['SoundRecordingDetailsByTerritory']['DisplayArtist']['ArtistRole']

      expect(element_result.collect_attributes.map(&:name)).to eq %w[Namespace UserDefinedValue]
    end

    describe 'External type definition' do
      let(:header) { element.collect_elements.first }

      it 'gives the type string' do
        expect(header.type).to eq 'ern:MessageHeader'
      end

      it 'gives the remote complex_type, linked by type' do
        expect(header.complex_type.name).to eq 'MessageHeader'
      end

      it 'includes child elements defined in external the complex type type definitions' do
        expected_elements = %w[MessageThreadId MessageId MessageFileName MessageSender SentOnBehalfOf MessageRecipient
                               MessageCreatedDateTime MessageAuditTrail Comment MessageControlType]

        expect(header.collect_elements.map(&:name)).to eq expected_elements
      end
    end
  end

  context 'with referencing example file' do
    let(:file) { fixture_file(%w[referencing.xsd], read: false) }

    it "gives an element's child through reference element" do
      expect(reader['Album', 'Tracks', 'Track', 'ISRC'].type).to eq 'xs:NCName'
    end

    it "gives the element's name obtained through reference" do
      expect(reader.elements[0].collect_elements[0].name).to eq 'Source'
    end

    it "gives an element's ref attribute value" do
      expect(reader['Album']['Source'].ref).to eq 'Source'
    end

    it 'gives the type of an elements obtained through the referenced element' do
      expect(reader['Album']['Source'].type).to eq 'xs:string'
    end

    it 'gives child elements defined in the referenced element' do
      expected_elements = %w[ISRC Artist Title DiscNumber TrackNumber Duration Label
                             Company CompanyCountry RecordedCountry RecordedYear ReleaseDate Contributors]

      expect(reader['Album', 'Tracks'].collect_elements.map(&:name)).to eq ['Track']
      expect(reader['Album', 'Tracks', 'Track'].collect_elements.map(&:name)).to eq expected_elements
    end

    it 'gives attributes defined in the referenced element' do
      expect(reader['Album', 'Tracks', 'Track'].collect_attributes).to eq []
      expect(reader['Album', 'Tracks', 'Track', 'Contributors', 'Contributor'].collect_attributes.map(&:name)).to eq ['credited']
    end
  end

  context 'with overriding namespaces per element' do
    let(:file) { fixture_file(%w[rosavia-epgu/schemas.xsd], read: false) }

    it "correctly resolves complex_type" do
      expect(reader['FormDataResponse']['changeOrderInfo'].complex_type).not_to be_nil
    end
  end

  context 'with gkh example file' do
    subject(:element) { reader['importWorkingListRequest', 'Signature', 'SignedInfo'] }

    let(:file) { fixture_file(%w[gkh hcs-services-types.xsd], read: false) }

    describe '#mixed_content?' do
      it 'checks for mixed content' do
        expect(element).not_to be_mixed_content
        expect(element['CanonicalizationMethod']).to be_mixed_content
      end
    end

    describe '#data_type' do
      it 'calculates data_type' do
        elem = reader['importWorkingListRequest', 'ApprovedWorkingListData', 'TransportGUID']
        expect(elem.data_type).to eq('string')
      end
    end

    describe '#absolute_name' do
      it 'calculates absolute_name' do
        expect(element.absolute_name).to eq('{http://www.w3.org/2000/09/xmldsig#}SignedInfo')
      end
    end

    describe '#namespace' do
      it 'retrieves namespace (accounting referenced elements)' do
        result1 = reader['importWorkingListRequest']['ApprovedWorkingListData'].namespace
        result2 = reader['importWorkingListRequest']['ApprovedWorkingListData']['TransportGUID'].namespace

        expect(result1).to eq('http://dom.gosuslugi.ru/schema/integration/services/')
        expect(result2).to eq('http://dom.gosuslugi.ru/schema/integration/base/')
      end
    end

    describe '#form' do
      it 'retrieves default form value from schema' do
        result = reader['importWorkingListRequest'].form

        expect(result).to eq('qualified')
      end
    end

    describe '#documentation' do
      it 'retrieves documentation for referenced elements' do
        result = reader['importWorkingListRequest']['ApprovedWorkingListData']['TransportGUID'].documentation

        expect(result).to eq(['Транспортный идентификатор'])
      end
    end
  end

  context 'with rkzn example file' do
    subject(:element) { reader['ChargeCreationRequest', 'ChargeTemplate', 'Discount'] }

    let(:file) { fixture_file(%w[rkzn ChargeCreation.xsd], read: false) }

    describe '#substitutable_elements' do
      it 'gets all substitutable elements' do
        expect(element.substitutable_elements.map(&:name)).to eq(%w[DiscountSize DiscountFixed MultiplierSize])
      end
    end
  end
end
