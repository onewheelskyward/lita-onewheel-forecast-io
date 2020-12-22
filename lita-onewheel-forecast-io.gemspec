Gem::Specification.new do |spec|
  spec.name          = 'lita-onewheel-forecast-io'
  spec.version       = '1.15.4'
  spec.authors       = ['Andrew Kreps']
  spec.email         = ['andrew.kreps@gmail.com']
  spec.description   = <<-EOS
    A rather different take on the weather. <br/>
    !ansirain Portland, OR 97206, USA rain probability 21:30|████████████████████████████████████▇▇▇▇▇▇▇▇▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅|22:30 max 100% <br/>
    !dailyrain Portland, OR 97206, USA 48 hr rains |▇▇▇▅▅▅▅▃▅▅▃▃▃▃▅▇▇▇▇▇▅▅▁▁▁▁▁______▁▁▁▁▁▁▁▁▁▃▃▃▁▁▁▁| max 59.0% <br/>
    !ansitemp Portland, OR 97206, USA 24 hr temps: 8.44°C |▅▅▅▅▃▃▁_▁▁▅▅▇█████▇▅▅▃▁| 6.17°C  Range: 5.89°C - 12.17°C
EOS
  spec.summary       = %q{A text-based interactive query engine for http://forecast.io's api.}
  spec.homepage      = 'https://github.com/onewheelskyward/lita-onewheel-forecast-io'
  spec.license       = 'MIT'
  spec.metadata      = { 'lita_plugin_type' => 'handler'}

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'lita', '~> 4'

  spec.add_development_dependency 'bundler', '~> 2'
  # spec.add_development_dependency 'pry-byebug', '~> 3.1'
  spec.add_development_dependency 'rake', '~> 13'
  spec.add_development_dependency 'rack-test', '~> 0'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'simplecov', '~> 0'
  spec.add_development_dependency 'coveralls', '~> 0'

  spec.add_runtime_dependency 'rest-client', '~> 2'
  spec.add_runtime_dependency 'geocoder', '~> 1.5'
  spec.add_runtime_dependency 'multi_json', '~> 1.7'
  spec.add_runtime_dependency 'magic-eightball', '~> 0.0'
  spec.add_runtime_dependency 'tzinfo', '~> 1.2'
end
