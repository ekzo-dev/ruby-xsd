# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::AttributeGroup do
  subject(:reader) { XSD::XML.open(file, logger: spec_logger) }

  let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }
  let(:attribute_group) { reader.attribute_groups.first }

  describe '#name' do
    it 'gives the name of the global attribute group' do
      expect(reader.attribute_groups.map(&:name)).to eq %w[CommonAttributes]
    end
  end

  describe '#attributes' do
    it 'gives the nested attributes' do
      expect(attribute_group.attributes.map(&:name)).to eq %w[lang revision]
    end
  end

  describe '#collect_attributes' do
    it 'resolves the attribute group reference transparently for the referencing type' do
      expect(reader['Catalog']['Item'].collect_attributes.map(&:name).first(2)).to eq %w[lang revision]
    end

    it 'contributes no elements' do
      expect(attribute_group.collect_elements).to eq []
    end
  end
end
