# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::SimpleType do
  subject(:reader) { XSD::XML.open(file, logger: spec_logger) }

  let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }

  def simple_type(name)
    reader.simple_types.find { |type| type.name == name }
  end

  describe '#linked?' do
    it 'is true for a named (global) type' do
      expect(simple_type('SizeType')).to be_linked
    end

    it 'is false for an anonymous nested type' do
      expect(simple_type('NestedListType').list.simple_type).not_to be_linked
    end
  end

  describe '#name' do
    it 'collects the global types of the schema and of everything it pulls in' do
      expect(reader.simple_types.map(&:name)).to eq %w[SizeType CountType ExclusiveCountType SizeOrCountType
                                                       NestedUnionType TagListType NestedListType AnonymousBaseType
                                                       RegionCodeType]
    end
  end

  describe '#documentation' do
    it 'gives the annotation of the type' do
      expect(simple_type('SizeType').documentation).to eq ['Size of an item']
    end
  end

  describe '#data_type' do
    it 'resolves a built-in restriction base' do
      expect(simple_type('SizeType').data_type).to eq 'string'
    end

    it 'resolves a restriction base transitively' do
      expect(simple_type('ExclusiveCountType').data_type).to eq 'decimal'
    end

    it 'resolves a restriction with an anonymous nested base type' do
      expect(simple_type('AnonymousBaseType').restriction.base).to be_nil
      expect(simple_type('AnonymousBaseType').data_type).to eq 'int'
    end

    it 'gives every distinct type of a union' do
      expect(simple_type('SizeOrCountType').data_type).to eq %w[string int]
    end

    it 'collapses a union whose members share one type' do
      expect(simple_type('NestedUnionType').data_type).to eq 'token'
    end

    it 'is always a string for a list' do
      expect(simple_type('TagListType').data_type).to eq 'string'
      expect(simple_type('NestedListType').data_type).to eq 'string'
    end
  end
end
