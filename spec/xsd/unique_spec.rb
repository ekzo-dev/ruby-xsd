# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Unique do
  subject(:unique) { catalog.unique.first }

  let(:reader) { XSD::XML.open(file, logger: spec_logger) }
  let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }
  let(:catalog) { reader['Catalog'] }

  it 'is exposed as a child of the element' do
    expect(catalog.unique.map(&:class)).to eq [described_class]
  end

  it 'gives the selector and the fields' do
    expect(unique.selector.xpath).to eq 'ks:Item'
    expect(unique.fields.map(&:xpath)).to eq ['ks:Title']
  end

  it 'has no nested elements' do
    expect(unique.collect_elements).to eq []
  end
end
