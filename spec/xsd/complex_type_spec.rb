# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::ComplexType do
  subject(:reader) { XSD::XML.open(file, logger: spec_logger, resource_resolver: resource_resolver(file)) }

  context 'with gkh example file' do
    subject(:element) { reader['importWorkingListRequest', 'Signature', 'SignedInfo', 'CanonicalizationMethod'] }

    let(:file) { fixture_file(%w[gkh hcs-services-types.xsd], read: false) }

    describe '#mixed' do
      it 'reads mixed property as boolean' do
        expect(element.complex_type.mixed).to eq(true)
      end
    end
  end

  context 'with XSDShemas example file' do
    subject(:element) { reader['VehicleMassMeasure'] }

    let(:file) { fixture_file(%w[XSDShemas EPTSAllData_v1.0.0.xsd], read: false) }

    describe '#data_type' do
      it 'reads data_type from simple_content' do
        expect(element.complex_type.data_type).to eq('decimal')
      end
    end
  end
end
