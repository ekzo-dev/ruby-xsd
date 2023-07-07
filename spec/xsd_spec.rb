# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe XSD::XML do
  subject(:reader) { described_class.open(file, :logger => spec_logger, resource_resolver: resource_resolver(file)) }

  context 'with ddex-v36 example files' do
    let(:file) { fixture_file(%w[ddex-v36 ddex-ern-v36.xsd], read: false) }

    describe '#elements' do
      it 'gives all child element definitions' do
        expect(reader.all_elements.map(&:name)).to eq %w[NewReleaseMessage CatalogListMessage]
        expect(reader.all_elements[0].all_elements[0].name).to eq 'MessageHeader'
      end
    end

    describe '[] operator' do
      it 'gives a child element object (matching by name)' do
        expect(reader['NewReleaseMessage'].name).to eq 'NewReleaseMessage'
      end

      it 'supports linking' do
        attribute_names = reader['NewReleaseMessage']['ReleaseList']['Release'].all_attributes.map(&:name)

        expect(attribute_names).to eq %w[LanguageAndScriptCode IsMainRelease]
      end

      it 'gives a specific element in the hierarchy when passing an array argument' do
        arguments = %w[NewReleaseMessage ResourceList SoundRecording]

        expect(reader[arguments].name).to eq 'SoundRecording'
        expect(reader[arguments].multiple_allowed?).to be true
      end

      it 'automatically turns symbol arguments into strings' do
        expect(reader[:NewReleaseMessage].name).to eq 'NewReleaseMessage'
      end

      it 'automatically turns symbol arguments into strings (supports linking)' do
        expected_attributes = %w[LanguageAndScriptCode IsMainRelease]

        expect(reader[:NewReleaseMessage]['ReleaseList'][:Release].all_attributes.map(&:name)).to eq expected_attributes
        expect(reader[:NewReleaseMessage, 'ReleaseList', :Release].all_attributes.map(&:name)).to eq expected_attributes
      end

      it "return nil and doesn't raise an exceptions when getting invalid input" do
        expect do
          expect(reader[:NewReleaseMessage, 'Nothing', '@Whatever', 'Foo']).to be_nil
        end.not_to raise_error
      end
    end

    describe '#min_occurs' do
      it 'gives the minOccurs attribute as an integer' do
        expect(reader['NewReleaseMessage']['ResourceList']['SoundRecording'].min_occurs).to eq 0
      end

      it 'returns 1 when an element has no minOccurs attribute specified' do
        expect(reader['NewReleaseMessage']['ResourceList'].min_occurs).to eq 1
      end
    end

    describe '#max_occurs' do
      it "returns the :unbounded symbol when there's no limit to the number of occurences of the element" do
        expect(reader['NewReleaseMessage']['ResourceList']['SoundRecording'].max_occurs).to eq :unbounded
      end
    end

    describe '#multiple_allowed?' do
      it 'indicates if multiple instances of an element are allowed' do
        expect(reader['NewReleaseMessage']['ResourceList'].multiple_allowed?).to be false
        expect(reader['NewReleaseMessage']['ResourceList']['SoundRecording'].multiple_allowed?).to be true
      end
    end

    describe '#required?' do
      it 'indicates if an element is required' do
        expect(reader['NewReleaseMessage'].required?).to be true
        expect(reader['NewReleaseMessage']['ResourceList'].required?).to be true
        expect(reader['NewReleaseMessage']['CollectionList'].required?).to be false
      end

      it 'indicates if an attribute is required' do
        expect(reader['NewReleaseMessage']['@MessageSchemaVersionId'].required?).to be true
        expect(reader['NewReleaseMessage']['@LanguageAndScriptCode'].required?).to be false
      end
    end

    describe '#optional?' do
      it 'indicates if an element is optonal (opposite of required)' do
        expect(reader['NewReleaseMessage'].optional?).to be false
        expect(reader['NewReleaseMessage']['ResourceList'].optional?).to be false
        expect(reader['NewReleaseMessage']['CollectionList'].optional?).to be true
      end
    end

    describe 'imports' do
      it 'finds imported types for elements' do
        simple_type = reader['NewReleaseMessage']['DealList']['ReleaseDeal']['Deal']['DealTerms']['WebPolicy']['AccessLimitation'].simple_type

        expect(simple_type.class).to eq XSD::SimpleType
        expect(simple_type.name).to eq 'AccessLimitation'
        expect(simple_type.schema).to be reader.schema.imports[0].imported_schema
      end
    end

    describe '#linked_complex_type' do
      it 'finds complex types for elements within the same schema' do
        el = reader['NewReleaseMessage']['MessageHeader']
        ct = el.complex_type

        expect(ct.class).to eq XSD::ComplexType
        expect(ct.name).to eq 'MessageHeader'
        expect(ct.schema).to be el.schema
      end
    end
  end

  context 'with ddex-v32 example files' do
    let(:file) { fixture_file(%w[ddex-v32 ern-main.xsd], read: false) }

    describe '#all_elements' do
      it 'includes elements from linked complex types from an imported schema' do
        element = reader['NewReleaseMessage']['CollectionList']['Collection']['Title']
        expected_elements = %w[TitleText SubTitle]

        expect(element.all_elements.map(&:name)).to eq expected_elements
      end

      it 'includes elements from extensions in linked complex types' do
        el = reader['NewReleaseMessage']['ResourceList']['SoundRecording']['SoundRecordingDetailsByTerritory']
        expected_elements = %w[TerritoryCode ExcludedTerritoryCode Title DisplayArtist ResourceContributor
                               IndirectResourceContributor RightsAgreementId LabelName RightsController RemasteredDate
                               OriginalResourceReleaseDate PLine CourtesyLine SequenceNumber HostSoundCarrier
                               MarketingComment Genre ParentalWarningType AvRating TechnicalSoundRecordingDetails
                               FulfillmentDate Keywords Synopsis]

        expect(el.all_elements.map(&:name)).to eq expected_elements
      end
    end

    describe '#schema_for_namespace' do
      it 'returns the schema object for a specified namespace' do
        namespace = 'http://ddex.net/xml/2010/ern-main/32'
        expect(reader.schema.schema_for_namespace(namespace).target_namespace).to eq namespace
        expect(reader.schema.schema_for_namespace(namespace)).to be reader.schema
        expect(reader.schema.schema_for_namespace(namespace)).to be reader.schema
        expect(reader['NewReleaseMessage'].schema_for_namespace(namespace)).to be reader.schema
      end

      it 'returns the schema object for a specified namespace code' do
        expect(reader.schema.schema_for_namespace('ernm').target_namespace).to eq 'http://ddex.net/xml/2010/ern-main/32'
        expect(reader.schema.schema_for_namespace('ernm')).to be reader.schema
        expect(reader['NewReleaseMessage']['ResourceList'].schema_for_namespace('ernm')).to be reader.schema
      end

      it 'finds imported schemas' do
        namespace = 'http://ddex.net/xml/20100712/ddexC'

        expect(reader.schema.schema_for_namespace(namespace).target_namespace).to eq namespace
        expect(reader.schema.schema_for_namespace('ddexC').target_namespace).to eq namespace
        expect(reader.schema.schema_for_namespace('ddex').target_namespace).to eq 'http://ddex.net/xml/20100712/ddex'

        expect(reader.schema.schema_for_namespace(namespace)).to be reader.schema.imports[1].imported_schema
        expect(reader.schema.schema_for_namespace('ddex')).to be reader.schema.imports[0].imported_schema
        expect(reader.schema.schema_for_namespace('ddexC')).to be reader.schema.imports[1].imported_schema
      end
    end
  end

  context 'with referencing example file' do
    subject(:element) { reader['Album', 'Tracks', 'Track', 'Contributors', 'Contributor'] }

    let(:file) { fixture_file(%w[referencing.xsd], read: false) }

    describe '#referenced_element' do
      it 'gives the referenced element' do
        expect(element.reference.class).to eq XSD::Element
        expect(element.reference.name).to eq 'Contributor'
        expect(element.reference).to_not eq element
      end
    end

    describe '# elements' do
      it 'gives elements of the referenced element' do
        expect(element.all_elements.map(&:name)).to eq ['Name', 'Role', 'Instrument']
      end
    end

    describe '#attributes' do
      it 'gives the attributes of the referenced element' do
        expect(element.all_attributes.map(&:name)).to eq ['credited']
      end
    end

    describe '#[]' do
      it 'lets the caller acces elements of the referenced element' do
        expect(element['Role'].type).to eq 'xs:NCName'
      end

      it 'lets the caller access attributes of the referened element' do
        expect(element['@credited'].type).to eq 'xs:boolean'
      end
    end

    describe '#name' do
      it 'gives the name of the referenced element' do
        expect(element.name).to eq 'Contributor'
      end
    end

    describe '#type' do
      it 'gives the type of the referenced element' do
        expect(element.type).to be_nil
        expect(reader['Album', 'Source'].type).to eq 'xs:string'
      end
    end

    describe '#complex_type' do
      it 'gives the complex type object of the referenced element' do
        expect(element.complex_type.sequence.elements.map(&:name)).to eq %w[Name Role Instrument]
      end
    end
  end
end
