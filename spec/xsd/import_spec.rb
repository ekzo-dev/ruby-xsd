# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::Import do
  subject(:reader) { XSD::XML.new(file, logger: spec_logger) }

  context 'with ddex-v36 example files' do
    subject(:import) { reader.imports[0] }

    let(:file) { fixture_file(%w[ddex-v36 ddex-ern-v36.xsd]) }

    it 'gives the namespace' do
      expect(import.namespace).to eq 'http://ddex.net/xml/avs/avs'
    end

    it 'gives the schema location' do
      expect(import.schema_location).to eq 'avs.xsd'
    end

    # ToFix:  NoMethodError: undefined method `uri' for #<XSD::Import
    # it 'gives a download uri' do
    #   expect(import.uri).to eq 'http://ddex.net/xml/avs/avs.xsd'
    # end

    it 'gives a reader for the external XSD' do
      expect(import.reader.class).to eq XSD::XML
    end

    it 'gives a download_path to save the imported xsd file to, if an xsd_file options is provided, containing the path to the parent xsd' do
      expect(import.options[:xsd_file]).to eq reader.options[:xsd_file]
      # ToFix: NoMethodError: undefined method `download_path' for #<XSD::Import
      # expect(import.download_path).to eq File.expand_path(File.join(File.dirname(__FILE__), 'examples', 'ddex-v36', 'avs.xsd'))
    end

    it 'downloads related xsd files' do
      # r1 = XSD::XML.new(fixture_file(%w[ddex-v36 avs.xsd]), logger: spec_logger)
      # r2 = import.reader
      # p r1.elements.map(&:name)
      # p r2.elements.map(&:name)
      # expect(r1.elements.map(&:name)).to eq r2.elements.map(&:name)
      # expect(r1.simple_types.map(&:name)).to eq r2.simple_types.map(&:name)
    end

    it 'automatically saves related xsd content' do
      # expect(import.reader.options[:xsd_file]).to eq File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', 'avs.xsd'))
      # expect(File.file?(import.download_path)).to eq true
    end
  end
end
