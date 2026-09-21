# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Group do
  subject(:reader) { XSD::XML.open(file, logger: spec_logger) }

  let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }
  let(:group) { reader.groups.first }

  describe '#name' do
    it 'gives the name of the global group' do
      expect(reader.groups.map(&:name)).to eq %w[DescriptionGroup]
    end
  end

  describe '#sequence' do
    it 'gives the nested sequence' do
      expect(group.sequence).to be_a XSD::Sequence
      expect(group.sequence.elements.map(&:name)).to eq %w[Title Description]
      expect(group.all).to be_nil
      expect(group.choice).to be_nil
    end
  end

  describe '#collect_elements' do
    it 'resolves the group reference transparently for the referencing type' do
      expect(reader['Catalog']['Item'].collect_elements.map(&:name).first(2)).to eq %w[Title Description]
    end

    it 'gives the elements of the referenced group' do
      base = reader['Catalog']['Item'].complex_type.complex_content.extension.base_complex_type
      reference = base.sequence.groups.first

      expect(reference).to be_referenced
      expect(reference.ref).to eq 'ks:DescriptionGroup'
      expect(reference.collect_elements.map(&:name)).to eq %w[Title Description]
    end
  end
end
