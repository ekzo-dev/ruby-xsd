# frozen_string_literal: true

require_relative 'lib/xsd/version'

Gem::Specification.new do |spec|
  spec.name    = 'xsd'
  spec.version = XSD::VERSION
  spec.authors = ['d.arkhipov']
  spec.email   = ['d.arkhipov@netcitylife.ru']

  spec.summary     = 'The Ruby XSD library is an XML Schema implementation for Ruby.'
  spec.description =
    'The Ruby XSD library is an XML Schema implementation for Ruby.Provides easy and flexible access to XSD information'

  spec.homepage              = 'https://github.com/ekzo-dev/ruby-xsd'
  spec.license               = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri']   = 'https://github.com/ekzo-dev/ruby-xsd/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'builder', '~> 3.2'
  spec.add_dependency 'nokogiri', '~> 1.11'
  spec.add_dependency 'rake', '~> 13.0'
  spec.add_dependency 'rest-client', '~> 2.1'

  spec.add_development_dependency 'logger', '~> 1.5'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'rubocop-performance', '~> 1.17'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.10'
end
