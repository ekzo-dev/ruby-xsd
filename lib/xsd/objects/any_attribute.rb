# frozen_string_literal: true

module XSD
  # The anyAttribute element enables the author to extend the XML document with attributes not specified by the schema.
  # Parent elements: complexType, restriction (both simpleContent and complexContent), extension (both simpleContent
  # and complexContent), attributeGroup
  # https://www.w3schools.com/xml/el_anyattribute.asp
  class AnyAttribute < BaseObject
    # Optional. Specifies the namespaces containing the attributes that can be used. Can be set to one of the following:
    #   ##any             - attributes from any namespace is allowed (this is default)
    #   ##other           - attributes from any namespace that is not the namespace of the parent element can be present
    #   ##local           - attributes must come from no namespace
    #   ##targetNamespace - attributes from the namespace of the parent element can be present
    #     List of {URI references of namespaces, ##targetNamespace, ##local} - attributes from a space-delimited list
    #                        of the namespaces can be present
    # @!attribute namespace
    # @return String
    property :namespace, :string, default: '##any'

    # Optional. Specifies how the XML processor should handle validation against the elements specified by this any
    # element. Can be set to one of the following:
    #   strict - the XML processor must obtain the schema for the required namespaces and validate the elements (this
    #              is default)
    #   lax    - same as strict but; if the schema cannot be obtained, no errors will occur
    #   skip   - The XML processor does not attempt to validate any elements from the specified namespaces
    # @!attribute process_contents
    # @return String, nil
    property :processContents, :string, default: 'strict'
  end
end
