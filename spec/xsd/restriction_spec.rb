# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Restriction do
  subject(:reader) { XSD::XML.open(file, :logger => spec_logger, resource_resolver: resource_resolver(file)) }

  context 'with rkzn example files' do
    let(:file) { fixture_file(%w[rkzn ChargeCreation.xsd], read: false) }

    describe '#collect_attributes' do
      it 'filters duplicate attributes in complex restrictions' do
        element = reader['ChargeCreationRequest', 'ChargeTemplate', 'Payer']

        expect(element.collect_attributes.map(&:name)).to eq %w[payerIdentifier payerName additionalPayerIdentifier]
        expect(element.collect_attributes(false).map(&:name)).to eq %w[payerIdentifier payerName additionalPayerIdentifier]
        expect(element.collect_attributes.first.simple_type.restriction.facets['length']).to eq('22')
      end
    end
  end

  context 'with kitchen-sink example files' do
    subject(:reader) { XSD::XML.open(file, logger: spec_logger) }

    let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }
    let(:restriction) { reader.simple_types.find { |type| type.name == 'SizeType' }.restriction }

    describe '#base' do
      it 'gives the base type name' do
        expect(restriction.base).to eq 'xs:string'
      end

      it 'is nil for a restriction with a nested anonymous base' do
        anonymous = reader.simple_types.find { |type| type.name == 'AnonymousBaseType' }.restriction

        expect(anonymous.base).to be_nil
        expect(anonymous.base_simple_type).to be_nil
        expect(anonymous.base_complex_type).to be_nil
        expect(anonymous.simple_type.data_type).to eq 'int'
      end
    end

    describe '#base_simple_type' do
      it 'resolves a base declared in the same schema' do
        exclusive = reader.simple_types.find { |type| type.name == 'ExclusiveCountType' }.restriction

        expect(exclusive.base_simple_type.name).to eq 'CountType'
      end

      it 'is nil for a built-in base' do
        expect(restriction.base_simple_type).to be_nil
      end
    end

    describe '#facets' do
      it 'maps enumerations to their documentation' do
        expect(restriction.facets['enumeration']).to eq('S' => ['Small'], 'M' => ['Medium'], 'L' => [])
      end

      it 'collects every pattern into a list' do
        expect(restriction.facets['pattern']).to eq ['[SML]', '\\w']
      end

      it 'keeps a single valued facet as a string' do
        expect(restriction.facets).to include('minLength' => '1', 'maxLength' => '1', 'whiteSpace' => 'collapse')
      end

      it 'covers the numeric facets' do
        count = reader.simple_types.find { |type| type.name == 'CountType' }.restriction

        expect(count.facets)
          .to eq('minInclusive' => '0', 'maxInclusive' => '100', 'totalDigits' => '5', 'fractionDigits' => '2')
      end

      it 'is empty for a restriction without facets' do
        expect(reader['Catalog']['RestrictedItem'].complex_type.complex_content.restriction.facets).to eq({})
      end
    end

    describe '#collect_elements' do
      it 'does not include the elements of the base type, which a restriction must repeat' do
        restricted = reader['Catalog']['RestrictedItem']

        expect(restricted.collect_elements.map(&:name)).to eq %w[Title Size]
        expect(reader['Catalog']['Item'].collect_elements.map(&:name)).to include('Description')
      end

      it 'includes the base type elements when explicitly asked to' do
        inner = reader['Catalog']['RestrictedItem'].complex_type.complex_content.restriction

        expect(inner.collect_elements(true).map(&:name)).to include('Description')
      end
    end

    describe '#collect_attributes' do
      it 'keeps the restricting declaration of an attribute redeclared from the base type' do
        restricted = reader['Catalog']['RestrictedItem']
        lang = restricted.collect_attributes.find { |attr| attr.name == 'lang' }

        expect(restricted.collect_attributes.map(&:name).tally['lang']).to eq 1
        expect(lang).to be_required
      end
    end

    describe 'particles' do
      it 'exposes the particle the restriction declares' do
        inner = reader['Catalog']['RestrictedItem'].complex_type.complex_content.restriction

        expect(inner.sequence).to be_a XSD::Sequence
        expect(inner.choice).to be_nil
        expect(inner.all).to be_nil
        expect(inner.group).to be_nil
      end
    end
  end
end
