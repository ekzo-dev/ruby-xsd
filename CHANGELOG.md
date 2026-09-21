## [Unreleased]

### Fixed

- `XSD::XML.open` resolves relative import/include locations against the schema they were read from, so the default
  resource resolver no longer requires a custom one for ordinary multi-file schemas
- `Schema#validate` writes included schemas into the temporary directory too, so schemas wired together with
  `<xs:include>` can be validated
- `Schema#validate` serializes the temporary schemas as UTF-8, so schemas in another encoding no longer fail to load
- `XML#logger` no longer raises `NameError` when no logger is configured (`logger` was never required)
- `BaseObject#parent` returns `nil` instead of raising when the parent node has no XSD object (document, `wsdl:types`)
- `object_by_name` passes the searched name as an xpath variable instead of interpolating it into the expression
- `ComplexType#mixed_content?` and `#data_type` no longer raise on a `complexContent`/`simpleContent` without a
  derivation
- An `<xs:include>` of a schema without a target namespace ("chameleon" include) is accepted
- Import/include cycles no longer yield duplicated definitions
- The compiled validator no longer leaks an open file descriptor
- `Element#attributes?` and `ComplexType#complex_content?` return booleans instead of the underlying objects
- Import/include error messages name the namespaces that did not match

### Changed

- Imported/included schemas are loaded once per location and shared, instead of being re-read and re-parsed for every
  reference to them
- Property, link and child lookups cache `nil` and `false` results, which cuts repeated xpath searches (roughly 2.5x
  faster traversal of the bundled example schemas)
- `XSD::XML#add_schema_xml`/`#add_schema_node` accept a `location:` keyword, and `Schema#location` exposes it
- `XML#object_cache` is keyed by node identity (`Hash#compare_by_identity`) rather than by `node.object_id`, which
  lets the `Lint/HashCompareByIdentity` rule be enabled again

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
