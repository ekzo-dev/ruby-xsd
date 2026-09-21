# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::XML do
  subject(:reader) { described_class.open(file, :logger => spec_logger, resource_resolver: resource_resolver(file)) }

  context 'with ddex-v36 example files' do
    let(:file) { fixture_file(%w[ddex-v36 ddex-ern-v36.xsd], read: false) }

    it 'gives a schema_node namespaces' do
      node_namespaces = {
        'xmlns:xs'  => 'http://www.w3.org/2001/XMLSchema',
        'xmlns:ern' => 'http://ddex.net/xml/ern/36',
        'xmlns:avs' => 'http://ddex.net/xml/avs/avs'
      }

      expect(reader.schema.namespaces).to eq(node_namespaces)
    end

    it 'gives a schema reader' do
      expect(reader.schema.class).to eq XSD::Schema
    end

    it "gives an elements shortcut to its schema's shortcuts" do
      expect(reader.elements.map(&:name)).to eq reader.schema.collect_elements.map(&:name)
    end
  end

  context 'with ddex-mlc example files' do
    let(:file) { fixture_file(%w[ddex-mlc music-licensing-companies.xsd], read: false) }

    it 'reads referenced schemas which bind the xmlschema namespace to the root namespace instead of xs' do
      expect(reader['DeclarationOfSoundRecordingRightsClaimMessage'].collect_elements.first.name).to eq 'MessageHeader'
    end

    it 'returns <xs:any> in collect_elements list' do
      element = reader['ManifestMessage']['FtpMessageHeader']['Signature']['KeyInfo']['X509Data'].collect_elements.last

      expect(element.name).to eq '#any'
      expect(element).to be_multiple_allowed
    end
  end

  context 'with kitchen-sink example files' do
    subject(:reader) { described_class.open(file, logger: spec_logger) }

    let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }

    describe '.open' do
      it 'resolves relative import locations against the schema it read them from' do
        expect(reader['Catalog']['Region'].collect_elements.map(&:name)).to eq %w[Code Name]
      end

      it 'resolves a relative include of an imported schema against that schema, not against the root one' do
        expect(reader['Catalog']['Region']['Code'].simple_type.name).to eq 'RegionCodeType'
      end

      it 'records the location of the schema it read' do
        expect(reader.schema.location).to eq file.to_s
      end
    end

    describe '#load_schema' do
      it 'rejects an empty location' do
        expect { reader.load_schema(nil) }.to raise_error(XSD::ImportError, /location must be provided/)
        expect { reader.load_schema('') }.to raise_error(XSD::ImportError, /location must be provided/)
      end
    end

    describe '#schemas' do
      it 'holds every schema pulled in so far, primary one first' do
        reader.simple_types

        expect(reader.schemas.first).to be reader.schema
        expect(reader.schemas.map(&:target_namespace))
          .to eq ['urn:kitchen-sink', nil, 'urn:kitchen-sink:imported', 'urn:kitchen-sink:imported']
      end
    end

    describe '#schemas_for_namespace' do
      it 'selects the schemas with a matching target namespace' do
        reader.simple_types

        expect(reader.schemas_for_namespace('urn:kitchen-sink')).to eq [reader.schema]
        expect(reader.schemas_for_namespace('urn:kitchen-sink:imported').size).to eq 2
        expect(reader.schemas_for_namespace('urn:nope')).to eq []
      end
    end

    describe '#complex_types' do
      it 'collects the global complex types of every schema without duplicates' do
        expect(reader.complex_types.map(&:name))
          .to eq %w[MeasureType AbstractItemType ItemType RestrictedItemType MixedTextType DerivedMixedType
                    ChameleonType RegionType]
      end
    end

    describe '#attributes' do
      it 'collects the global attributes of every schema' do
        expect(reader.attributes).to eq []
      end
    end

    describe '#[]' do
      it 'is nil when no schema has a matching definition' do
        expect(reader['Nope']).to be_nil
      end
    end

    describe '#tmp_dir' do
      it 'is nil unless configured' do
        expect(reader.tmp_dir).to be_nil
        expect(described_class.new(tmp_dir: '/tmp').tmp_dir).to eq '/tmp'
      end
    end
  end

  describe '#logger' do
    it 'gives the configured logger' do
      expect(described_class.new(logger: spec_logger).logger).to be spec_logger
    end

    it 'falls back to a warn level stdout logger' do
      logger = described_class.new.logger

      expect(logger).to be_a Logger
      expect(logger.level).to eq Logger::WARN
    end
  end

  describe '#add_schema_xml' do
    it 'rejects xml whose root is not a schema element' do
      expect { described_class.new.add_schema_xml('<nope/>') }
        .to raise_error(XSD::Error, /does not seem to be a valid XSD/)
    end

    it 'rejects xml that cannot be parsed into a document with a root' do
      expect { described_class.new.add_schema_xml('') }.to raise_error(XSD::Error, /does not seem to be a valid XSD/)
    end
  end

  describe '#add_schema_node' do
    it 'rejects anything that is not a nokogiri node' do
      expect { described_class.new.add_schema_node('<xs:schema/>') }
        .to raise_error(XSD::Error, /must be of type Nokogiri::XML::Node/)
    end

    it 'accepts a schema node embedded in another document, with the namespaces it inherits' do
      wsdl = Nokogiri::XML(fixture_file(%w[mvd service.wsdl]))
      node = wsdl.at_xpath('//xs:schema', 'xs' => XSD::BaseObject::XML_SCHEMA)
      reader = described_class.new(logger: spec_logger)

      expect(reader.add_schema_node(node)).to be_a XSD::Schema
      expect(reader.schema.target_namespace).to eq 'http://v2_4_3.incomingRequests.webservices.kernel.sx.fms.ru'
      expect(node.namespace_definitions).to be_empty
      expect(reader.schema.namespace_prefix).to eq 'xs'
      expect(reader.schema.nodes(:element).size).to eq 12
    end
  end

  describe 'DEFAULT_RESOURCE_RESOLVER' do
    it 'reads an absolute path' do
      xml = described_class::DEFAULT_RESOURCE_RESOLVER.call(fixture_file(%w[referencing.xsd], read: false).to_s, nil)

      expect(xml).to include 'xs:schema'
    end

    it 'refuses a relative location, which only the reader itself can resolve' do
      expect { described_class::DEFAULT_RESOURCE_RESOLVER.call('nope.xsd', 'urn:x') }
        .to raise_error(XSD::ImportError, /Failed to locate import 'nope.xsd' for namespace 'urn:x'/)
    end
  end
end
