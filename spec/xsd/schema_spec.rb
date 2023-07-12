# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Schema do
  subject(:reader) { XSD::XML.open(file, logger: spec_logger, resource_resolver: resource_resolver(file)) }

  context 'with ddex-v36 example files' do
    subject(:schema) { reader.schema }

    let(:file) { fixture_file(%w[ddex-v36 ddex-ern-v36.xsd], read: false) }

    describe '#elements' do
      it 'gives a element readers' do
        expect(schema.elements.map(&:class)).to eq [XSD::Element] * 2
      end
    end

    describe '#target_namespace' do
      it 'gives the target namespace' do
        expect(schema.target_namespace).to eq 'http://ddex.net/xml/ern/36'
      end
    end

    describe '#namespaces' do
      it 'returns a hash of namespace shortcuts' do
        expected_namespaces = {
          'xmlns:xs'  => 'http://www.w3.org/2001/XMLSchema',
          'xmlns:ern' => 'http://ddex.net/xml/ern/36',
          'xmlns:avs' => 'http://ddex.net/xml/avs/avs'
        }
        expect(schema.namespaces).to eq(expected_namespaces)
      end
    end

    describe '#import_by_namespace' do
      it 'returns import objects for the given namespace' do
        import = schema.import_by_namespace('http://ddex.net/xml/avs/avs')

        expect(import.class).to eq XSD::Import
        expect(import).to be schema.imports[0]
        expect(import.namespace).to eq 'http://ddex.net/xml/avs/avs'

        # ToFix: expected: "http://ddex.net/xml/avs/avs" got "http://ddex.net/xml/ern/36"
        expect(import.imported_schema.target_namespace).to eq 'http://ddex.net/xml/avs/avs'
      end

      it 'returns import objects for given namespace codes' do
        import = schema.import_by_namespace('avs')
        expect(import.class).to eq XSD::Import
        expect(import).to be schema.imports[0]
        expect(import.namespace).to eq 'http://ddex.net/xml/avs/avs'

        # ToFix: expected: "http://ddex.net/xml/avs/avs" got "http://ddex.net/xml/ern/36"
        expect(import.imported_schema.target_namespace).to eq 'http://ddex.net/xml/avs/avs'
      end

      it 'returns import objects for given namespace codes with xmlns prefix' do
        import = schema.import_by_namespace('xmlns:avs')
        expect(import.class).to eq XSD::Import
        expect(import).to be schema.imports[0]
        expect(import.namespace).to eq 'http://ddex.net/xml/avs/avs'

        # ToFix: expected: "http://ddex.net/xml/avs/avs" got "http://ddex.net/xml/ern/36"
        expect(import.imported_schema.target_namespace).to eq 'http://ddex.net/xml/avs/avs'
      end

      it 'returns nil when no matching import is found' do
        expect(schema.import_by_namespace('foo')).to be_nil
      end

      it 'returns nil when a nil namespace is given' do
        expect(schema.import_by_namespace(nil)).to be_nil
      end
    end

    it 'includes imported definitions as if they were local' do
      expect(schema.simple_types.map(&:name)).to eq %w[ddex_LocalCollectionAnchorReference ddex_LocalResourceAnchorReference AccessLimitation AdministratingRecordCompanyRole AllTerritoryCode ArtistRole AudioCodecType BinaryDataType BusinessContributorRole CalculationType CarrierType CdProtectionType CharacterType CodingType CollectionType CommercialModelType CompilationType ContainerFormat CreationType CreativeContributorRole CueOrigin CueSheetType CueUseType CurrencyCode CurrentTerritoryCode DataMismatchResponseType DataMismatchStatus DataMismatchType DdexTerritoryCode DeductionRateType DeliveryActionType DeliveryMessageType DeprecatedCurrencyCode DeprecatedIsoTerritoryCode DigitizationMode DisputeReason DistributionChannelType DpidStatus DrmEnforcementType DrmPlatformType DsrMessageType EquipmentType ErnMessageType ErncFileStatus ErncProposedActionType ExpressionType ExternallyLinkedResourceType FileStatus FingerprintAlgorithmType GoverningAgreementType HashSumAlgorithmType ImageCodecType ImageType InvoiceAvailabilityStatus IsoCurrencyCode IsoLanguageCode IsoTerritoryCode LabelNameType LicenseOrClaimRefusalReason LicenseOrClaimRequestUpdateReason LicenseOrClaimUpdateReason LicenseRejectionReason LicenseStatus LicensingProcessStatus LodFileStatus LodProposedActionType MembershipType MessageActionType MessageContentRevenueType MessageContextType MessageControlType MidiType MlcMessageType MusicalWorkContributorRole MusicalWorkRightsClaimType MusicalWorkType MwlCaCMessageInBatchType MwnMessageType NewReleaseMessageStatus OperatingSystemType OrderType PLineType ParentalWarningType PartyRelationshipType PercentageType PriceInformationType PriceRangeType PriceType Priority ProductType ProjectContributorRelationshipType Purpose RateModificationType RatingAgency ReasonType RecipientRevenueType RecordingMode RedeliveryReasonType ReferenceUnit RelationalRelator ReleaseAvailabilityStatus ReleaseRelationshipType ReleaseResourceType ReleaseType ReportFormat ReportType RequestReason RequestedActionType ResourceContributorRole ResourceOmissionReason ResourceType RevenueSourceType RightShareRelationshipType RightShareType RightsClaimPolicyType RightsControllerRole RightsControllerType RightsCoverage RoyaltyRateCalculationType RoyaltyRateType SalesReportAvailabilityStatus Sex SheetMusicCodecType SheetMusicType SoftwareType SoundProcessorType SoundRecordingType SupplyChainStatus TaxScope TaxType TerritoryCodeType TerritoryCodeTypeIncludingDeprecatedCodes TextCodecType TextType ThemeType TisTerritoryCode TitleType TrackContributorRelationshipType UnitOfBitRate UnitOfConditionValue UnitOfExtent UnitOfFrameRate UnitOfFrequency UpdateIndicator UseType UserInterfaceType ValueType VideoCodecType VideoContentType VideoDefinitionType VideoType VisualPerceptionType VocalType WsMessageStatus TerritoryCode]
    end
  end

  context 'with fss example files' do
    let(:file) { fixture_file(%w[fss SID0003416_schema.xsd], read: false) }

    describe '#namespace_prefix' do
      it 'gives the correct result for empty prefix' do
        expect(reader.schema.namespace_prefix).to be_nil
      end

      it 'finds built-in and linked types' do
        expect(reader['SvedSostRaschRequest']['SvedSostRaschJurRequest']['dateStart'].complex_type).to be_nil
        expect(reader['SvedSostRaschRequest']['SvedSostRaschJurRequest']['organization'].simple_type.class).to be XSD::SimpleType
      end
    end

    describe '#validate' do
      it 'validates schema with imports' do
        expect { reader.schema.validate }.not_to raise_error
      end

      it 'validates xml against schema with imports' do
        expect { reader.schema.validate_xml(fixture_file(%w[fss samples Request0.xml])) }.not_to raise_error
      end
    end
  end

  context 'with mvd example files' do
    describe '#validate' do

      it 'validates schema from WSDL document' do
        wsdl = Wasabi.document(fixture_file(%w[mvd service.wsdl]))

        xsd = XSD::XML.new(logger: spec_logger)
        xsd.add_schema_node(wsdl.parser.schemas.first)

        expect { xsd.schema.validate }.not_to raise_error
      end
    end
  end
end
