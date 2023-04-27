# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe XSD do
  subject(:reader) { described_class::XML.new(file, :logger => spec_logger) }

  context 'with ddex-v36 example files' do
    let(:file) { fixture_file(%w[ddex-v36 ddex-ern-v36.xsd]) }

    describe 'caching' do
      it 'start with caches empty' do
        cache_names = %i[direct_elements attributes all_elements sequences choices
                         complex_types linked_complex_type simple_contents extensions]

        expect(
          cache_names.map { |name| "#{name}: #{reader.instance_variable_get("@#{name}").inspect}" }
        ).to eq(cache_names.map { |name| "#{name}: #{nil.inspect}" })
      end

      it 'caches some relationships to improve performance' do
        expect(reader.instance_variable_get(:@schema)).to be_nil
        expect(reader.instance_variable_get(:@elements)).to be_nil
        # the next line causes new caches to be created
        expect(reader['NewReleaseMessage'].instance_variable_get(:@all_elements)).to be_nil
        expect(reader.instance_variable_get(:@schema).class).to eq XSD::Schema

        # ToFix: "NoMethodError: undefined method `length' for nil:NilClasss"
        # expect(reader.schema.instance_variable_get(:@direct_elements).length).to eq 2

        # the next line causes new caches to be created
        expect(reader['NewReleaseMessage']['NewReleaseMessage'].instance_variable_get(:@all_elements)).to be_nil

        # ToFix: "NoMethodError: undefined method `first' for nil:NilClass"
        # expect(reader['NewReleaseMessage'].instance_variable_get(:@all_elements).first.name).to eq 'MessageHeader'
      end
    end

    describe '#elements' do
      it 'gives all child element definitions' do
        expect(reader.elements.map(&:name)).to eq %w[NewReleaseMessage CatalogListMessage]

        # ToFix: undefined method `elements' for #<XSD::Element
        # expect(reader.elements[0].elements[0].name).to eq 'MessageHeader'
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

    # ToFix: infinite loop
    # describe '#child_elements?' do
    #   it 'returns wether an element has child element definitions or not' do
    #     expect(reader['NewReleaseMessage'].child_elements?).to eq true
    #     expect(reader['NewReleaseMessage']['MessageHeader']['MessageThreadId'].child_elements?).to eq false
    #   end
    # end

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
        skip 'to fix'
        # ToFix: loop
        # simple_type =
        #   reader['NewReleaseMessage']['DealList']['ReleaseDeal']['Deal']['DealTerms']['WebPolicy']['AccessLimitation']
        #     .linked_simple_type

        # expect(simple_type.class).to eq XSD::SimpleType
        # expect(simple_type.name).to eq 'AccessLimitation'
        #  # byebug
        # expect(simple_type.schema).to be reader.imports[0].reader.schema
      end
    end

    describe '#linked_complex_type' do
      it 'finds complex types for elements within the same schema' do
        skip 'to fix'
        # el = reader['NewReleaseMessage']['MessageHeader']
        # ToFix: linked_complex_type
        # ct = el.linked_complex_type

        # expect(ct.class).to eq XSD::ComplexType
        # expect(ct.name).to eq 'MessageHeader'
        # expect(ct.schema).to be el.schema
      end
    end
  end

  context 'with ddex-v32 example files' do
    let(:file) { fixture_file(%w[ddex-v32 ern-main.xsd]) }

    describe '#all_elements' do
      it 'includes elements from linked complex types from an imported schema' do
        element           = reader['NewReleaseMessage']['CollectionList']['Collection']['Title']
        expected_elements = %w[TitleText SubTitle]

        expect(element.all_elements.map(&:name)).to eq expected_elements
      end

      # ToFix: undefined method `elements' for #<XSD::Element
      # it 'includes elements from extensions in linked complex types' do
      #   el = reader['NewReleaseMessage']['ResourceList']['SoundRecording']['SoundRecordingDetailsByTerritory']
      #   expected_elements = %w[TerritoryCode ExcludedTerritoryCode Title DisplayArtist ResourceContributor
      #                          IndirectResourceContributor RightsAgreementId LabelName RightsController RemasteredDate
      #                          OriginalResourceReleaseDate PLine CourtesyLine SequenceNumber HostSoundCarrier
      #                          MarketingComment Genre ParentalWarningType AvRating TechnicalSoundRecordingDetails
      #                          FulfillmentDate Keywords Synopsis]
      #
      #   expect(el.elements.map(&:name)).to eq expected_elements
      # end
    end

    describe '#schema_for_namespace' do
      it 'returns the schema object for a specified namespace' do
        skip 'to fix'
        # ToFix: XSD::Error:
        # Schema not found for namespace 'http://ddex.net/xml/2010/ern-main/32' in 'http://ddex.net/xml/2010/ern-main/32
        # namespace = 'http://ddex.net/xml/2010/ern-main/32'
        # expect(reader.schema_for_namespace(namespace).target_namespace).to eq namespace
        # expect(reader.schema_for_namespace(namespace)).to be reader.schema
        # expect(reader.schema.schema_for_namespace(namespace)).to be reader.schema
        # expect(reader['NewReleaseMessage'].schema_for_namespace(namespace)).to be reader.schema
      end

      it 'returns the schema object for a specified namespace code' do
        expect(reader.schema_for_namespace('ernm').target_namespace).to eq 'http://ddex.net/xml/2010/ern-main/32'
        expect(reader.schema_for_namespace('ernm')).to be reader.schema
        expect(reader.schema.schema_for_namespace('ernm')).to be reader.schema
        expect(reader['NewReleaseMessage']['ResourceList'].schema_for_namespace('ernm')).to be reader.schema
      end

      it 'finds imported schemas' do
        namespace = 'http://ddex.net/xml/20100712/ddexC'

        expect(reader.schema_for_namespace(namespace).target_namespace).to eq namespace
        expect(reader.schema_for_namespace('ddexC').target_namespace).to eq namespace

        expect(reader.schema.schema_for_namespace('ddex').target_namespace)
          .to eq 'http://ddex.net/xml/20100712/ddex'

        # ToFix: infinite loop
        # expect(reader.schema_for_namespace(namespace)).to be reader.imports[1].reader.schema
        # expect(reader.schema.schema_for_namespace('ddex')).to be reader.imports[0].reader.schema
        # expect(reader.schema_for_namespace('ddexC')).to be reader.imports[1].reader.schema
      end
    end
  end

  context 'with referencing example file' do
    subject(:element) { reader['Album', 'Tracks', 'Track', 'Contributors', 'Contributor'] }

    let(:file) { fixture_file(%w[referencing.xsd]) }

    describe '#referenced_element' do
      it 'gives the referenced element' do
        skip 'to fix'
        # ToFix: referenced_element
        # expect(element.referenced_element.class).to eq XSD::Element
        # expect(element.referenced_element.name).to eq 'Contributor'
        # expect(element.referenced_element).to_not eq element
      end
    end

    # ToFix elements' for #<XSD::Element
    # describe '#elements' do
    #   it 'gives alements of the referenced element' do
    #   expect(element.elements.map(&:name)).to eq ['Name', 'Role', 'Instrument']
    # end
    # end

    # ToFix elements' for #<XSD::Element
    # describe '#attributes' do
    #   it 'gives the attributes of the referenced element' do
    #     expect(element.attributes.map(&:name)).to eq ['credited']
    #   end
    # end

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

    # ToFix: undefined method `sequences' for #<XSD::ComplexType
    # describe '#complex_type' do
    #   it 'gives the complex type object of the referenced element' do
    #     expect(element.complex_type.sequences.first.elements.map(&:name)).to eq %w[Name Role Instrument]
    #   end
    # end
  end
end
