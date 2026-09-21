# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::AnyAttribute do
  subject(:reader) { XSD::XML.open(file, logger: spec_logger) }

  let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }
  let(:any_attribute) { reader['Catalog']['Item'].collect_attributes.last }

  it 'is returned as part of the attribute list' do
    expect(any_attribute).to be_a described_class
    expect(any_attribute.name).to eq '#anyAttribute'
  end

  it 'gives the namespace and the process contents' do
    expect(any_attribute.namespace).to eq '##other'
    expect(any_attribute.process_contents).to eq 'skip'
  end
end
