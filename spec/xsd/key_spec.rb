# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Key do
  subject(:key) { catalog.map_child(:key) }

  let(:reader) { XSD::XML.open(file, logger: spec_logger) }
  let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }
  let(:catalog) { reader['Catalog'] }

  it 'gives the name' do
    expect(key.name).to eq 'ItemKey'
  end

  it 'gives the selector and the fields' do
    expect(key.selector).to be_a XSD::Selector
    expect(key.selector.xpath).to eq 'ks:Item'
    expect(key.fields.map(&:class)).to eq [XSD::Field]
    expect(key.fields.map(&:xpath)).to eq ['@sku']
  end

  it 'has no nested elements or attributes' do
    expect(key.collect_elements).to eq []
    expect(key.collect_attributes).to eq []
  end
end
