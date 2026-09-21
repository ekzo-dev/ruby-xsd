# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Union do
  subject(:reader) { XSD::XML.open(file, logger: spec_logger) }

  let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }
  let(:union) { reader.simple_types.find { |type| type.name == 'SizeOrCountType' }.union }

  describe '#member_types' do
    it 'splits the memberTypes attribute' do
      expect(union.member_types).to eq %w[ks:SizeType xs:int]
    end

    it 'defaults to an empty list' do
      nested = reader.simple_types.find { |type| type.name == 'NestedUnionType' }.union

      expect(nested.member_types).to eq []
    end
  end

  describe '#types' do
    it 'resolves named members and keeps built-in ones as strings' do
      expect(union.types.map { |type| type.is_a?(String) ? type : type.name }).to eq ['SizeType', 'xs:int']
    end

    it 'gives the nested anonymous simple types' do
      nested = reader.simple_types.find { |type| type.name == 'NestedUnionType' }.union

      expect(nested.types.map(&:class)).to eq [XSD::SimpleType, XSD::SimpleType]
    end
  end
end
