Lita.configure do |config|
  # Register at https://developer.forecast.io/ to receive a key.
  # You get 1000 calls for free per day...
  # Might as well verify the api URL is current while you're there.
  # Oh, and set colors to bool option of your liking.
  config.handlers.onewheel_forecast_io.api_key = 'yourforecastiokey'
  config.handlers.onewheel_forecast_io.api_uri = 'https://api.forecast.io/forecast/'
  config.handlers.onewheel_forecast_io.colors = true
end
