# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Annotation do
  subject(:reader) { XSD::XML.open(file, logger: spec_logger) }

  let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }
  let(:annotation) { reader.schema.map_child(:annotation) }

  describe '#documentations' do
    it 'gives the documentation objects' do
      expect(annotation.documentations.map(&:class)).to eq [XSD::Documentation]
      expect(annotation.documentations.first.node.text).to eq 'Schema exercising every construct the library maps.'
    end
  end

  describe '#appinfos' do
    it 'gives the appinfo objects with their source' do
      expect(annotation.appinfos.map(&:class)).to eq [XSD::Appinfo]
      expect(annotation.appinfos.first.source).to eq 'urn:kitchen-sink:appinfo'
    end
  end

  it 'contributes no elements or attributes to its parent' do
    expect(annotation.collect_elements).to eq []
    expect(annotation.collect_attributes).to eq []
  end
end
