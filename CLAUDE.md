# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Ruby gem implementing a Lita chat handler for weather forecasting. Integrates with PirateWeather (main branch) and Apple WeatherKit (weatherkit branch), plus PurpleAir for air quality.

## Testing

```bash
bundle exec rspec -fp spec          # full suite
bundle exec rspec spec/path.rb:LINE # single test by line number
```

Tests use `webmock` to stub HTTP requests — add/update fixtures in `spec/fixtures/` when adding new API calls. Redis must be running locally for tests (per CircleCI config).

## Required Config

Handler requires these Lita config values at runtime:

- `api_key` — PirateWeather or WeatherKit API key
- `api_uri` — weather API base URL
- `geocoder_key` — optional, for geocoding service
- `purpleair_api_key` — optional, for air quality data
- `default_location` — defaults to `'Portland, OR'`
- `colors` — boolean, enables ANSI color output

## Working Style

- Propose a plan before making changes
- Explain tradeoffs when refactoring
- If writing scripts to investigate, write them in ruby instead of python