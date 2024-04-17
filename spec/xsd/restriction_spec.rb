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
end
