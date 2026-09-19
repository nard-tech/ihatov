# frozen_string_literal: true

require_relative 'lib/ihatov/version'

Gem::Specification.new do |spec|
  spec.name = 'ihatov'
  spec.version = Ihatov::VERSION
  spec.authors = ['Fujita Shu']
  spec.summary = '岩手の文学から、ひとこと。'
  spec.description = 'Source-aware, reproducible literary sample data from Iwate.'
  spec.homepage = 'https://github.com/nard-tech/ihatov'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.4'
  spec.files = Dir['lib/**/*.rb', 'data/**/*.yml', 'README.md', 'LICENSE', 'docs/*.md']
  spec.require_paths = ['lib']
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['documentation_uri'] = "#{spec.homepage}#readme"
end
