# frozen_string_literal: true

module XSD
  # The attribute element defines an attribute.
  # Parent elements: attributeGroup, schema, complexType, restriction (both simpleContent and complexContent),
  # extension (both simpleContent and complexContent)
  # https://www.w3schools.com/xml/el_attribute.asp
  class Attribute < BaseObject
    TYPE_PROPERTY = :type

    include SimpleTyped
    include Referenced
    include Named

    # Optional. Specifies the name of the attribute. Name and ref attributes cannot both be present
    # @!attribute name
    # @return String, nil
    property :name, :string

    # Optional. Specifies a default value for the attribute. Default and fixed attributes cannot both be present
    # @!attribute default
    # @return String, nil
    property :default, :string

    # Optional. Specifies a fixed value for the attribute. Default and fixed attributes cannot both be present
    # @!attribute fixed
    # @return String, nil
    property :fixed, :string

    # Optional. Specifies the form for the attribute. The default value is the value of the attributeFormDefault
    # attribute of the schema containing the attribute. Can be set to one of the following:
    #   qualified   - indicates that this attribute must be qualified with the namespace prefix and the no-colon-name
    #                 (NCName) of the attribute
    #   unqualified - indicates that this attribute is not required to be qualified with the namespace prefix and is
    #                 matched against the (NCName) of the attribute
    # @!attribute form
    # @return String
    property :form, :string, default: proc { schema.attribute_form_default }

    # Optional. Specifies a built-in data type or a simple type. The type attribute can only be present when the
    # content does not contain a simpleType element
    # @!attribute type
    # @return String, nil
    property :type, :string

    # Optional. Specifies how the attribute is used. Can be one of the following values:
    #   optional   - the attribute is optional (this is default)
    #   prohibited - the attribute cannot be used
    #   required   - the attribute is required
    # @!attribute use
    # @return String
    property :use, :string, default: 'optional'

    # Determine if attribute is required
    # @return Boolean
    def required?
      use == 'required'
    end

    # Determine if attribute is optional
    # @return Boolean
    def optional?
      use == 'optional'
    end

    # Determine if attribute is prohibited
    # @return Boolean
    def prohibited?
      use == 'prohibited'
    end

    # Get base data type
    # @return String, nil
    def data_type
      if simple_type
        simple_type.data_type
      else
        strip_prefix(type)
      end
    end
  end
end
