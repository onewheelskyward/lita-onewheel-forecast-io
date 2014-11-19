module Lita
  module Handlers
    class ForecastIo < Handler
      config :forecast_io_api_key
      config :forecast_io_url

      route(/^!rain/, :is_it_raining)

      def is_it_raining(response)
        forecast = get_forecast_io_results
        response.reply 'no'
      end

      def get_forecast_io_results(query = '45.5252,-122.6751')
        # gps_coords, long_name = get_gps_coords query
        url = config.forecast_io_url + config.forecast_io_api_key + '/' + query
        puts url
        forecast = HTTParty.get url
        forecast['long_name'] = long_name   # Hacking the location into the hash.
        forecast
      end

    end

    Lita.register_handler(ForecastIo)
  end
end
