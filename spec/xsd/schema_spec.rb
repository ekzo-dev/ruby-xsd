# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Schema do
  subject(:reader) { XSD::XML.open(file, logger: spec_logger, resource_resolver: resource_resolver(file)) }

  describe '#declaration_node' do
    let(:files) do
      {
        'main.xsd' => <<~XML,
          <?xml version="1.0"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:t="urn:t" targetNamespace="urn:t">
            <xs:include schemaLocation="types.xsd"/>
            <xs:element name="Order" type="t:Order"/>
            <xs:complexType name="Order"><xs:sequence>
              <xs:element name="Code" type="t:Code"/>
              <xs:element name="Inner"><xs:complexType><xs:sequence><xs:element name="X" type="xs:string"/></xs:sequence></xs:complexType></xs:element>
            </xs:sequence></xs:complexType>
            <xs:simpleType name="Twice"><xs:restriction base="xs:string"/></xs:simpleType>
            <xs:simpleType name="Twice"><xs:restriction base="xs:int"/></xs:simpleType>
          </xs:schema>
        XML
        'types.xsd' => <<~XML
          <?xml version="1.0"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" targetNamespace="urn:t">
            <xs:simpleType name="Code"><xs:restriction base="xs:string"><xs:maxLength value="3"/></xs:restriction></xs:simpleType>
          </xs:schema>
        XML
      }
    end

    let(:reader) do
      XSD::XML.new(logger: spec_logger, resource_resolver: proc { |location, _| files[location] }).tap do |reader|
        reader.add_schema_xml(files['main.xsd'], location: 'main.xsd')
      end
    end

    it 'finds a top-level declaration by its kind and name' do
      expect(reader.schema.declaration_node(:complexType, 'Order').name).to eq 'complexType'
      expect(reader.schema.declaration_node(:element, 'Order').name).to eq 'element'
      expect(reader.schema.declaration_node(:simpleType, 'Order')).to be_nil
    end

    it 'does not find a declaration nested in another one' do
      expect(reader.schema.declaration_node(:element, 'Inner')).to be_nil
    end

    it 'finds the first of two declarations of one name, as a query does' do
      expect(reader.schema.declaration_node(:simpleType, 'Twice').at_xpath('.//@base').value).to eq 'xs:string'
    end

    it 'resolves a reference by name through it, in an included schema too' do
      code = reader['Order']['Code']

      expect(code.simple_type.name).to eq 'Code'
      expect(code.simple_type.restriction.base).to eq 'xs:string'
    end
  end

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

  context 'with retail_license_notification example file' do
    subject(:schema) { reader.schema }

    let(:file) { fixture_file(%w[retail_license_notification scheme.xsd], read: false) }

    describe '#schemas_for_namespace' do
      it 'gets schema for unprefixed namespace' do
        expect(schema.schemas_for_namespace('').first.target_namespace).to eq('urn://fsrar/smev/retail_license_notification/types/1.0.0')
        expect(schema.object_by_name('complexType', 'DocumentType').name).to eq('DocumentType')
      end
    end
  end

  context 'with gkn example files, whose schemas are wired together with includes' do
    let(:file) { fixture_file(%w[gkn CR_ZC_REQ_Reqest.xsd], read: false) }

    describe '#validate' do
      it 'validates a schema that pulls in other schemas with include' do
        expect { reader.schema.validate }.not_to raise_error
      end

      it 'memoizes the compiled validator' do
        validator = reader.schema.validate

        expect(validator).to be_a Nokogiri::XML::Schema
        expect(reader.schema.validate).to be validator
      end
    end
  end

  context 'with kitchen-sink example files' do
    subject(:reader) { XSD::XML.open(file, logger: spec_logger) }

    let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }
    let(:schema) { reader.schema }

    describe 'properties' do
      it 'reads the schema level defaults' do
        expect(schema.version).to eq '1.4'
        expect(schema.element_form_default).to eq 'qualified'
        expect(schema.attribute_form_default).to eq 'unqualified'
        expect(schema.block_default).to eq 'extension'
        expect(schema.final_default).to eq 'list'
      end

      it 'falls back to the XSD defaults when the attributes are absent' do
        bare = XSD::XML.open(fixture_file(%w[referencing.xsd], read: false), logger: spec_logger).schema

        expect(bare.attribute_form_default).to eq 'unqualified'
        expect(bare.target_namespace).to be_nil
        expect(bare.version).to be_nil
      end
    end

    describe '#namespace_prefix' do
      it 'gives the prefix the XMLSchema namespace is bound to' do
        expect(schema.namespace_prefix).to eq 'xs'
      end
    end

    describe '#target_namespace_prefix' do
      it 'gives the prefix the target namespace is bound to' do
        expect(schema.target_namespace_prefix).to eq 'ks'
      end

      it 'is nil when the target namespace is not bound to any prefix' do
        bare = XSD::XML.open(fixture_file(%w[referencing.xsd], read: false), logger: spec_logger).schema

        expect(bare.target_namespace_prefix).to be_nil
      end
    end

    describe '#targets_namespace?' do
      it 'accepts the namespace itself as well as a prefix bound to it' do
        expect(schema.targets_namespace?('urn:kitchen-sink')).to be true
        expect(schema.targets_namespace?('ks')).to be true
      end

      it 'rejects anything else' do
        expect(schema.targets_namespace?('imp')).to be false
        expect(schema.targets_namespace?('urn:nope')).to be false
      end
    end

    describe '#collect_elements' do
      it 'is the list of global elements' do
        expect(schema.collect_elements).to eq schema.elements
        expect(schema.collect_elements.map(&:name)).to eq %w[Shape Circle Square SharedNote Catalog]
      end
    end

    describe '#collect_attributes' do
      it 'is the list of global attributes' do
        expect(schema.collect_attributes).to eq schema.attributes
      end
    end

    describe '#validate' do
      it 'validates a schema with both imports and includes' do
        expect { schema.validate }.not_to raise_error
      end
    end

    describe '#validate_xml' do
      it 'accepts a conforming document given as a string' do
        expect { schema.validate_xml(fixture_file(%w[kitchen-sink samples catalog-valid.xml])) }.not_to raise_error
      end

      it 'accepts a conforming document given as a pathname' do
        path = fixture_file(%w[kitchen-sink samples catalog-valid.xml], read: false)

        expect { schema.validate_xml(path) }.not_to raise_error
      end

      it 'accepts a conforming document given as a parsed document' do
        document = Nokogiri::XML(fixture_file(%w[kitchen-sink samples catalog-valid.xml]))

        expect { schema.validate_xml(document) }.not_to raise_error
      end

      it 'reports every violation of a non conforming document' do
        expect { schema.validate_xml(fixture_file(%w[kitchen-sink samples catalog-invalid.xml])) }
          .to raise_error(XSD::ValidationError, /attribute 'name' is required but missing.+not expected/m)
      end

      it 'rejects an unsupported input type' do
        expect { schema.validate_xml(42) }
          .to raise_error(XSD::ValidationError, /must be a String, Pathname or Nokogiri::XML::Document, got Integer/)
      end

      it 'reports malformed xml as a validation error' do
        expect { schema.validate_xml('<not-xml') }.to raise_error(XSD::ValidationError)
      end
    end
  end
end
