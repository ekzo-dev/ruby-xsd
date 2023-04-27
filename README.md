# XSD

[![Ruby](https://github.com/ekzo-dev/ruby-xsd/actions/workflows/main.yml/badge.svg)][githubactions]

[githubactions]: https://github.com/omniauth/omniauth/actions/workflows/main.yml

The Ruby XSD library is an [XML Schema](https://www.w3.org/2001/XMLSchema) implementation for Ruby. Provides easy and
flexible access to XSD information.

## Installation

Install as a gem

    $ gem install xsd

Or add it to your Gemfile

```ruby
gem 'xsd'
```

## Usage

```ruby
require 'xsd'

# Load ruby-xsd
reader = XSD::XML.new(:xsd_file => 'some.xsd')

# Get attributes
attribute = reader['NewReleaseMessage']['@MessageSchemaVersionId']

# Get atrribute information
attribute.name # => 'MessageSchemaVersionId'
attribute.type # => 'xs:string'
attribute.required? # => true

# Get element information
element = reader['NewReleaseMessage']['ResourceList']['SoundRecording']
element.min_occurs # => 0
element.max_occurs # => :unbounded
element.type # => 'ern:SoundRecording'
element.complex_type # => XSD::ComplexType
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can
also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ruby-xsd. This project is intended
to be a safe, welcoming space for collaboration, and contributors are expected to adhere to
the [code of conduct](https://github.com/[USERNAME]/ruby-xsd/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Ruby::Xsd project's codebases, issue trackers, chat rooms and mailing lists is expected to
follow the [code of conduct](https://github.com/[USERNAME]/ruby-xsd/blob/main/CODE_OF_CONDUCT.md).
