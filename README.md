# lita-onewheel-forecast-io

[![Build Status](https://travis-ci.org/onewheelskyward/lita-onewheel-forecast-io.png?branch=master)](https://travis-ci.org/onewheelskyward/lita-onewheel-forecast-io)
[![Coverage Status](https://coveralls.io/repos/onewheelskyward/lita-onewheel-forecast-io/badge.svg)](https://coveralls.io/r/onewheelskyward/lita-onewheel-forecast-io)
[![Documentation Status](https://readthedocs.org/projects/lita-onewheel-forecast-io/badge/?version=latest)](https://readthedocs.org/projects/lita-onewheel-forecast-io/?badge=latest)

This Lita handler takes location-based queries and returns interesting data about the weather.  Temperatures, rain chance and intensity, and wind speeds are all included.  But wait, there's more!  if you download now, you also get 8-ball style replies with `!rain` and `!snow`!

## Installation

Add lita-onewheel-forecast-io to your Lita instance's Gemfile, from github since it's currently unpublished:

``` ruby
gem 'lita-onewheel-forecast-io', github: 'onewheelskyward/lita-onewheel-forecast-io', branch: :master
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
