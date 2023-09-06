## [Unreleased]

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
