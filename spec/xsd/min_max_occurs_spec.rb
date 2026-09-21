# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::MinMaxOccurs do
  subject(:reader) { XSD::XML.open(file, logger: spec_logger) }

  let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }
  let(:item) { reader['Catalog']['Item'] }

  describe '#min_occurs' do
    it 'defaults to 1' do
      expect(item.min_occurs).to eq 1
    end

    it 'reads the attribute as an integer' do
      expect(item['Size'].min_occurs).to eq 0
    end
  end

  describe '#max_occurs' do
    it 'defaults to 1' do
      expect(item['Size'].max_occurs).to eq 1
    end

    it 'maps "unbounded" to a symbol' do
      expect(item.max_occurs).to eq :unbounded
    end
  end

  describe '#multiple?' do
    it 'is true when the definition itself may repeat' do
      expect(item).to be_multiple
    end

    it 'is false when the definition itself may occur at most once' do
      expect(item['Size']).not_to be_multiple
      expect(item['Note']).not_to be_multiple
    end
  end

  describe '#computed_max_occurs' do
    it 'is the declared value when no parent repeats' do
      expect(item['Size'].computed_max_occurs).to eq 1
    end

    it 'becomes unbounded when a parent is unbounded' do
      expect(item['Note'].max_occurs).to eq 1
      expect(item['Note'].computed_max_occurs).to eq :unbounded
    end
  end

  describe '#computed_min_occurs' do
    it 'is the declared value when no parent relaxes it' do
      expect(item['Title'].computed_min_occurs).to eq 1
    end

    it 'is 0 inside a choice, because a sibling may be picked instead' do
      expect(item['Note'].min_occurs).to eq 1
      expect(item['Note'].computed_min_occurs).to eq 0
    end
  end

  describe '#multiple_allowed?' do
    it 'accounts for repeating parents' do
      expect(item['Note']).not_to be_multiple
      expect(item['Note']).to be_multiple_allowed
    end

    it 'is false when neither the definition nor its parents repeat' do
      expect(item['Title']).not_to be_multiple_allowed
    end
  end

  describe 'required?/optional? derived from the computed values' do
    it 'treats an element inside a choice as optional' do
      expect(item['Note']).to be_optional
      expect(item['Note']).not_to be_required
    end

    it 'treats a mandatory element as required' do
      expect(item['Title']).to be_required
      expect(item['Title']).not_to be_optional
    end
  end
end
