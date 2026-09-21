# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Facet do
  subject(:reader) { XSD::XML.open(file, logger: spec_logger) }

  let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }
  let(:restriction) { reader.simple_types.find { |type| type.name == 'SizeType' }.restriction }

  it 'maps every facet element to a facet object' do
    expect(restriction.map_children(:enumeration).map(&:class)).to eq [described_class] * 3
  end

  describe '#value' do
    it 'gives the value attribute' do
      expect(restriction.map_children(:enumeration).map(&:value)).to eq %w[S M L]
      expect(restriction.map_child(:whiteSpace).value).to eq 'collapse'
    end
  end
end
