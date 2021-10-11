# lita-onewheel-forecast-io

[![Build Status](https://circleci.com/gh/onewheelskyward/lita-onewheel-forecast-io.svg?style=shield)
[![Coverage Status](https://coveralls.io/repos/onewheelskyward/lita-onewheel-forecast-io/badge.svg)](https://coveralls.io/r/onewheelskyward/lita-onewheel-forecast-io)

This Lita handler takes location-based queries and returns interesting data about the weather.  Temperatures, rain chance and intensity, and wind speeds are all included.  But wait, there's more!  if you download now, you also get 8-ball style replies with `!rain` and `!snow`!

# WARNING

With the upcoming deprecation of the Darksky api (12/2021) this handler will become useless.  I'm open to suggestions on new data sources, feel free to open an issue with an idea!


## Installation

Add lita-onewheel-forecast-io to your Lita instance's Gemfile, from github since it's currently unpublished:

``` ruby
gem 'lita-onewheel-forecast-io', '~> 0.0'
```

## Configuration

``` ruby
Lita.configure do |config|
  config.handlers.onewheel_forecast_io.api_key = 'yourforecastiokey'
  config.handlers.onewheel_forecast_io.api_uri = 'https://api.forecast.io/forecast/'
  config.handlers.onewheel_forecast_io.colors = true
end
```
Register at https://developer.forecast.io/ to receive an API key (1000 calls/day for free). Once you have your key go ahead and toss if into your config block. Set colors to bool option of your liking. Enjoy!

## Usage

!rain, !snow and other fine things.

## License

[MIT](http://opensource.org/licenses/MIT)

# hmm
	☀ ☀ 🔥 🔥 ☼  ☼  ☼
