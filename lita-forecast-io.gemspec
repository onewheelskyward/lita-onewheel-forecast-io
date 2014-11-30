Gem::Specification.new do |spec|
  spec.name          = 'lita-forecast-io'
  spec.version       = '0.0.1'
  spec.authors       = ['Andrew Kreps']
  spec.email         = ['andrew.kreps@gmail.com']
  spec.description   = %q{A text interface to Forecast.io's weather data.}
  spec.summary       = %q{Summarize THIS!}
  spec.homepage      = 'https://github.com/onewheelskyward/lita-forecast-io'
  spec.license       = 'MIT'
  spec.metadata      = { 'lita_plugin_type' => 'handler'}

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'lita', '>= 4.0'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rspec', '>= 3.0.0'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'httparty'
  spec.add_development_dependency 'geocoder'
  spec.add_development_dependency 'multi_json', '1.7.8'
  # spec.add_runtime_dependency 'magic-eightball'
  spec.add_development_dependency 'magic-eightball'
end
