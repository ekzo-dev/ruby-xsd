## [Unreleased]

## [2.0.0] - 2023-07-07

- Change XSD::XML.new(file, **options) -> XSD::XML.open(file, **options)
- Add ability to construct empty reader (reader = XSD::XML.new(**options)) and manually add schemas to it (reader.add_schema_xml(xml))
- Add ability to configure import resources resolver via options

## [1.0.0] - 2023-04-25

- Initial release
