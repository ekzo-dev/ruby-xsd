## [2.7.10] - 2024-04-26

- Fix data_type detection in complex_type simple_content extension

## [2.7.9] - 2024-04-25

- Fix resolving schemas with unprefixed namespace

## [2.7.8] - 2024-04-22

- Return <xs:any> and <xs:anyAttribute> from collect_elements/collect_attributes
- Make multiple_allowed? available on all definitions with max occurs
- Don't return duplicated attributes from complex restriction
- Fix base_complex_type on restriction without base
- Improve substitutable elements detection
- Added mutiple? shorthand

## [2.6.3] - 2024-04-13

- Fix retrieving documentation for referenced elements
- Cache "namespace" call result

## [2.6.2] - 2024-04-12

- Get default value for element/attribute "form" property from schema

## [2.6.1] - 2024-04-12

- Correctly detect namespace for referenced elements

## [2.6.0] - 2024-04-12

- Fix XSD boolean attributes
- Add support for element lookup with namespace
- Add element (with simple content) data type calculation
- Add element mixed type calculation

## [2.4.3] - 2024-04-04

- Fix detecting types and refs when namespaces are overidden per element
- Fix documentation encoding issue with no XML declaration

## [2.4.1] - 2023-11-13

- Fix attribute value existence check

## [2.4.0] - 2023-11-13

- Fixed reading of SimpleType in List
- Add support for Restriction without base
- Support Any generation in simple scenarios

## [2.3.0] - 2023-09-06

- Fixed reading of SimpleType in List
- Add support for Restriction without base
- Support Any generation in simple scenarios

## [2.2.0] - 2023-07-10

- Fixed built-in types detection for unprefixed schema namespace
- Move validation to Schema object

## [2.1.0] - 2023-07-10

- Add support for &lt;xs:include&gt; element
- Changed method "schema_for_namespace(namespace) -> XSD::Schema" signature to "schemas_for_namespace(namespace) -> Array&lt;XSD::Schema&gt;"

## [2.0.0] - 2023-07-07

- Change XSD::XML.new(file, **options) -> XSD::XML.open(file, **options)
- Add ability to construct empty reader (reader = XSD::XML.new(**options)) and manually add schemas to it (reader.add_schema_xml(xml))
- Add ability to configure import resources resolver via options

## [1.0.0] - 2023-04-25

- Initial release
