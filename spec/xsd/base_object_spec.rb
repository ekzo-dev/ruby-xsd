# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe XSD::BaseObject do
  subject(:reader) { XSD::XML.open(file, logger: spec_logger) }

  let(:file) { fixture_file(%w[kitchen-sink kitchen-sink.xsd], read: false) }
  let(:catalog) { reader['Catalog'] }

  describe '#initialize' do
    it 'rejects a non hash parameter' do
      expect { XSD::Element.new('nope') }.to raise_error(XSD::Error, /expects a hash parameter/)
    end
  end

  describe '#inspect' do
    it 'includes the class name and the node path' do
      expect(catalog.inspect).to eq '#<XSD::Element path=/xs:schema/xs:element[5]>'
    end
  end

  describe '#id' do
    it 'is nil when the node carries no id' do
      expect(catalog.id).to be_nil
    end
  end

  describe '#namespaces' do
    it 'gives the namespaces in scope for the node' do
      expect(catalog.namespaces).to include('xmlns:ks' => 'urn:kitchen-sink')
    end
  end

  describe '#parent' do
    it 'gives the object of the parent node' do
      expect(catalog.parent).to be_a XSD::Schema
      expect(catalog['Item'].parent).to be_a XSD::Sequence
    end

    it 'is nil for the schema itself, whose parent node is the document' do
      expect(reader.schema.parent).to be_nil
    end
  end

  describe '#strip_prefix' do
    it 'removes the namespace prefix' do
      expect(catalog.strip_prefix('ks:Item')).to eq 'Item'
      expect(catalog.strip_prefix('Item')).to eq 'Item'
      expect(catalog.strip_prefix(nil)).to be_nil
    end
  end

  describe '#get_prefix' do
    it 'extracts the namespace prefix' do
      expect(catalog.get_prefix('ks:Item')).to eq 'ks'
      expect(catalog.get_prefix('Item')).to be_nil
      expect(catalog.get_prefix(nil)).to be_nil
    end
  end

  describe '#[]' do
    it 'matches any definition with an asterisk' do
      expect(catalog['*'].name).to eq 'Item'
      expect(catalog['@*'].name).to eq 'name'
    end

    it 'matches a namespaced query' do
      expect(reader['{urn:kitchen-sink}Catalog'].name).to eq 'Catalog'
    end

    it 'does not match a query with a different namespace' do
      expect(reader['{urn:other}Catalog']).to be_nil
    end

    it 'is nil for an unknown name' do
      expect(reader['Nope']).to be_nil
      expect(catalog['Item']['Nope']).to be_nil
    end

    it 'stops walking as soon as a segment does not match' do
      expect(catalog[%w[Nope Item]]).to be_nil
    end

    it 'rejects a malformed namespaced query' do
      expect { reader.schema['{urn:kitchen-sink'] }.to raise_error(XSD::Error, %r{Invalid element/attribute query})
    end
  end

  describe '#object_by_name' do
    it 'finds a global definition by qualified name' do
      expect(catalog.object_by_name(:complexType, 'ks:ItemType').name).to eq 'ItemType'
    end

    it 'does not look up built-in types' do
      expect(catalog.object_by_name(:simpleType, 'xs:string')).to be_nil
    end

    it 'treats the name as a value rather than as part of the xpath expression' do
      expect(catalog.object_by_name(:complexType, 'ks:foo"] | //*[1]')).to be_nil
    end

    it 'is nil when nothing matches' do
      expect(catalog.object_by_name(:complexType, 'ks:Missing')).to be_nil
    end
  end

  describe '#schemas_for_namespace' do
    it 'raises for an unknown namespace' do
      expect { catalog.schemas_for_namespace('nope') }.to raise_error(XSD::Error, /Schema not found for namespace/)
    end

    it 'returns the schema and its includes for the target namespace' do
      schemas = catalog.schemas_for_namespace('ks')

      expect(schemas.first).to be reader.schema
      expect(schemas.size).to eq 2
    end
  end

  describe '#node_to_object' do
    it 'reuses the object cached for a node' do
      expect(catalog.node_to_object(catalog.node)).to be catalog
    end

    it 'raises for a node it has no class for' do
      node = reader.schema.node.document.create_element('nonsense')

      expect { catalog.node_to_object(node) }.to raise_error(XSD::Error, /Object class not found/)
    end
  end

  describe '#respond_to?' do
    it 'covers properties, links and children' do
      expect(catalog.respond_to?(:nillable)).to be true
      expect(catalog.respond_to?(:complex_type)).to be true
      expect(catalog.respond_to?(:unique)).to be true
    end

    it 'is false for anything else' do
      expect(catalog.respond_to?(:nope)).to be false
      expect { catalog.nope }.to raise_error(NoMethodError)
    end
  end

  describe 'property caching' do
    it 'computes a resolved link only once, even when it resolves to nil' do
      element = catalog['Item']['Size']
      allow(element).to receive(:object_by_name).and_call_original

      2.times { expect(element.complex_type).to be_nil }

      expect(element).to have_received(:object_by_name).once
    end

    it 'caches a property that resolves to false' do
      allow(catalog.node).to receive(:[]).and_call_original

      2.times { expect(catalog.nillable).to be false }

      expect(catalog.node).to have_received(:[]).with('nillable').once
    end

    it 'caches a child lookup that resolves to nil' do
      allow(catalog).to receive(:map_child).and_call_original

      2.times { expect(catalog.simple_type).to be_nil }

      expect(catalog).to have_received(:map_child).once
    end
  end

  describe '#documentation' do
    it 'is an empty array when the definition carries no annotation' do
      expect(catalog.documentation).to eq []
    end

    it 'falls back to the documentation of the referenced definition' do
      shared_note = catalog['SharedNote']

      expect(shared_note).to be_referenced
      expect(shared_note.documentation).to eq catalog.schema['SharedNote'].documentation
    end
  end
end
