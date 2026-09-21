# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Any do
  subject(:reader) { XSD::XML.open(file, logger: spec_logger) }

  let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }
  let(:any) { reader['Catalog']['Item'].collect_elements.last }

  it 'is returned as part of the element list' do
    expect(any).to be_a described_class
    expect(any.name).to eq '#any'
  end

  it 'gives the namespace and the process contents' do
    expect(any.namespace).to eq '##other'
    expect(any.process_contents).to eq 'lax'
  end

  it 'honours the occurs attributes' do
    expect(any).to be_multiple
    expect(any).to be_multiple_allowed
  end
end
