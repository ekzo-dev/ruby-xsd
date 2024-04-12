# frozen_string_literal: true

module XSD
  # The complexType element defines a complex type. A complex type element is an XML element that contains other
  # elements and/or attributes.
  # Parent elements: element, redefine, schema
  # https://www.w3schools.com/xml/el_complextype.asp
  class ComplexType < BaseObject
    include AttributeContainer
    include Named

    # Optional. Specifies a name for the element
    # @!attribute name
    # @return String
    property :name, :string

    # Optional. Specifies whether the complex type can be used in an instance document. True indicates that an element
    # cannot use this complex type directly but must use a complex type derived from this complex type. Default is false
    # @!attribute abstract
    # @return Boolean
    property :abstract, :boolean, default: false

    # Optional. Specifies whether character data is allowed to appear between the child elements of this complexType
    # element. Default is false. If a simpleContent element is a child element, the mixed attribute is not allowed!
    # @!attribute mixed
    # @return Boolean
    property :mixed, :boolean, default: false

    # Optional. Prevents a complex type that has a specified type of derivation from being used in place of this
    # complex type. This value can contain #all or a list that is a subset of extension or restriction:
    #   extension - prevents complex types derived by extension
    #   restriction - prevents complex types derived by restriction
    #   #all - prevents all derived complex types
    # @!attribute block
    # @return String, nil
    property :block, :string

    # Optional. Prevents a specified type of derivation of this complex type element. Can contain #all or a list
    # that is a subset of extension or restriction.
    #   extension - prevents derivation by extension
    #   restriction - prevents derivation by restriction
    #   #all - prevents all derivation
    # @!attribute final
    # @return String, nil
    property :final, :string

    # Simple content object
    # @!attribute simple_content
    # @return SimpleContent
    child :simple_content, :simpleContent

    # Complex content object
    # @!attribute complex_content
    # @return ComplexContent
    child :complex_content, :complexContent

    # Nested group
    # @!attribute group
    # @return Group
    child :group, :group

    # Nested all
    # @!attribute all
    # @return All
    child :all, :all

    # Nested choice
    # @!attribute choice
    # @return Choice
    child :choice, :choice

    # Nested sequence
    # @!attribute sequence
    # @return Sequence
    child :sequence, :sequence

    # Determine if this is a linked type
    # @return Boolean
    def linked?
      !name.nil?
    end

    # Determine if this type has mixed content definition
    # @return Boolean
    def mixed_content?
      return true if mixed

      if complex_content
        return true if complex_content.mixed

        return (complex_content.extension || complex_content.restriction).base_complex_type&.mixed_content?
      end

      false
    end

    # Determine if this type has complex content definition
    # @return Boolean
    def complex_content?
      if simple_content
        false
      elsif complex_content
        true
      else
        group || all || choice || sequence
      end
    end

    # Determine if this type has simple content definition
    # @return Boolean
    def simple_content?
      !!simple_content
    end

    # Get simple content data type
    # @return String, nil
    def data_type
      return nil unless simple_content

      restriction = simple_content.restriction
      if restriction
        if restriction.base
          restriction.base_simple_type&.data_type || strip_prefix(restriction.base)
        else
          restriction.simple_type&.data_type
        end
      else
        extension = simple_content.extension
        extension.base_simple_type&.data_type || strip_prefix(extension.base)
      end
    end
  end
end
