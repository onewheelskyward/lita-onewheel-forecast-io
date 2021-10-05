require 'simplecov'
require 'coveralls'
require 'webmock/rspec'
include WebMock::API

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start { add_filter '/spec/' }
Coveralls.wear!

require 'lita-onewheel-forecast-io'
require 'lita/rspec'

# A compatibility mode is provided for older plugins upgrading from Lita 3. Since this plugin
# was generated with Lita 4, the compatibility mode should be left disabled.
Lita.version_3_compatibility_mode = false
