# frozen_string_literal: true

require_relative 'lib/bunny_storage_client'

Gem::Specification.new do |spec|
  spec.name          = 'bunny_storage_client'
  spec.version       = ::BunnyStorageClient::VERSION
  spec.authors       = ['Ramit Koul']
  spec.email         = ['ramitkaul@gmail.com']

  spec.summary       = 'A Ruby Client SDK for interacting with BunnyCDN storage services.'
  spec.description   = 'BunnyStorage Client is a Ruby SDK for interacting with BunnyCDN storage services.'
  spec.homepage      = 'https://github.com/rkwap/bunny_storage_client'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*.rb']
  spec.bindir        = 'bin'
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.5'

  spec.add_dependency 'net-http', '~> 0.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/CHANGELOG.md"
end
