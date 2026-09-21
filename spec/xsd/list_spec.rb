# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::List do
  subject(:reader) { XSD::XML.open(file, logger: spec_logger) }

  let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }

  describe '#item_type' do
    it 'gives the itemType attribute' do
      expect(reader.simple_types.find { |type| type.name == 'TagListType' }.list.item_type).to eq 'xs:NMTOKEN'
    end
  end

  describe '#simple_type' do
    it 'gives the nested anonymous item type' do
      list = reader.simple_types.find { |type| type.name == 'NestedListType' }.list

      expect(list.item_type).to be_nil
      expect(list.simple_type.data_type).to eq 'int'
    end
  end
end
