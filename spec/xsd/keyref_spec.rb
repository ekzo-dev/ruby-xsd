# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Keyref do
  subject(:keyref) { catalog.map_child(:keyref) }

  let(:reader) { XSD::XML.open(file, logger: spec_logger) }
  let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }
  let(:catalog) { reader['Catalog'] }

  it 'gives the name and the referred constraint' do
    expect(keyref.name).to eq 'ItemRef'
    expect(keyref.refer).to eq 'ks:ItemKey'
  end

  it 'gives the selector and the fields' do
    expect(keyref.selector.xpath).to eq 'ks:Item/ks:Link'
    expect(keyref.fields.map(&:xpath)).to eq ['.']
  end
end
