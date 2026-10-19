# frozen_string_literal: true

require_relative '../spec_helper'

# A schema with no target namespace, included into a schema that has one ("chameleon" include): everything it
# declares belongs to the including namespace, and an unqualified name inside it names something of that
# namespace. Included into two namespaces, it declares two sets of definitions.
RSpec.describe 'a chameleon include' do
  let(:common) do
    <<~XSD
      <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified">
        <xs:include schemaLocation="parts/money-part.xsd"/>
        <xs:complexType name="Money"><xs:sequence>
          <xs:element name="value" type="Amount"/>
          <xs:element name="currency" type="Currency"/>
        </xs:sequence></xs:complexType>
      </xs:schema>
    XSD
  end
  let(:part) do
    <<~XSD
      <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
        <xs:simpleType name="Amount"><xs:restriction base="xs:int"/></xs:simpleType>
        <xs:simpleType name="Currency"><xs:restriction base="xs:string"/></xs:simpleType>
      </xs:schema>
    XSD
  end
  let(:orders) do
    <<~XSD
      <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:a="urn:orders" targetNamespace="urn:orders"
                 elementFormDefault="qualified">
        <xs:include schemaLocation="common.xsd"/>
        <xs:element name="Order"><xs:complexType><xs:sequence>
          <xs:element name="total" type="a:Money"/>
        </xs:sequence></xs:complexType></xs:element>
      </xs:schema>
    XSD
  end
  let(:invoices) do
    <<~XSD
      <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:b="urn:invoices" targetNamespace="urn:invoices"
                 elementFormDefault="qualified">
        <xs:include schemaLocation="common.xsd"/>
        <xs:element name="Invoice" type="b:Money"/>
      </xs:schema>
    XSD
  end

  # every file added up front, each at its location, as a host that keeps a set of files does
  subject(:reader) do
    XSD::XML.new(logger: spec_logger, resource_resolver: proc { |location| raise XSD::ImportError, "not in the set: #{location}" }).tap do |r|
      r.add_schema_xml(common, location: 'common.xsd')
      r.add_schema_xml(part, location: 'parts/money-part.xsd')
      r.add_schema_xml(orders, location: 'orders.xsd')
      r.add_schema_xml(invoices, location: 'invoices.xsd')
    end
  end

  let(:order_money) { reader['Order'].collect_elements.first.complex_type }
  let(:invoice_money) { reader['Invoice'].complex_type }

  it 'declares its types in the including namespace' do
    expect([order_money.name, order_money.namespace]).to eq %w[Money urn:orders]
    expect(order_money.absolute_name).to eq '{urn:orders}Money'
  end

  it 'resolves an unqualified name inside it in that namespace, through an include of its own' do
    value = order_money.collect_elements.find { |element| element.name == 'value' }

    expect([value.simple_type.name, value.simple_type.namespace]).to eq %w[Amount urn:orders]
    expect(value.namespace).to eq 'urn:orders'
  end

  it 'declares two sets of definitions when two namespaces include it' do
    expect(invoice_money.namespace).to eq 'urn:invoices'
    expect(invoice_money).not_to equal(order_money)
    expect(invoice_money.node).to equal(order_money.node)
  end

  it 'is among the schemas of the including namespace, as a view of the file' do
    schemas = reader.schemas_for_namespace('urn:orders')

    expect(schemas.map(&:location)).to eq %w[orders.xsd common.xsd parts/money-part.xsd]
    expect(schemas.drop(1)).to all(be_chameleon)
    expect(schemas.drop(1).map(&:target_namespace)).to all(eq 'urn:orders')
    expect(schemas[1].chameleon_source).to equal(reader.schemas.first)
    expect(schemas.last.simple_types.map { |type| [type.name, type.namespace] }).to eq [%w[Amount urn:orders], %w[Currency urn:orders]]
  end

  it 'does not stand for the absent namespace once included' do
    expect(reader.target_namespaces).to contain_exactly('urn:orders', 'urn:invoices')
  end

  it 'leaves a schema with no namespace that nobody includes in the absent one' do
    reader.add_schema_xml(%(<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"><xs:simpleType name="Loose"><xs:restriction base="xs:string"/></xs:simpleType></xs:schema>),
                          location: 'loose.xsd')

    expect(reader.target_namespaces).to contain_exactly('urn:orders', 'urn:invoices', nil)
    expect(reader.schemas_for_namespace(nil).map(&:location)).to include('loose.xsd')
  end

  it 'is found through an import of the including namespace too' do
    reader.add_schema_xml(<<~XSD, location: 'payments.xsd')
      <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:a="urn:orders" targetNamespace="urn:payments">
        <xs:import namespace="urn:orders" schemaLocation="orders.xsd"/>
        <xs:element name="Payment" type="a:Money"/>
      </xs:schema>
    XSD

    expect([reader['Payment'].complex_type.name, reader['Payment'].complex_type.namespace]).to eq %w[Money urn:orders]
  end

  it 'is not among the schemas of the absent namespace once included' do
    expect(reader.schemas_for_namespace(nil)).to be_empty
  end

  it 'still validates a document, as libxml applies the namespace itself' do
    schema = reader.schemas_for_namespace('urn:orders').first
    valid = '<Order xmlns="urn:orders"><total><value>3</value><currency>RUB</currency></total></Order>'
    wrong = '<Order xmlns="urn:orders"><total><value>x</value><currency>RUB</currency></total></Order>'

    expect { schema.validate_xml(valid) }.not_to raise_error
    expect { schema.validate_xml(wrong) }.to raise_error(XSD::ValidationError, /'\{urn:orders\}Amount'/)
  end
end
