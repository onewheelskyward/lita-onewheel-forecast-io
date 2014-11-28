require 'geocoder'
require 'httparty'
require_relative 'location'

module Lita
  module Handlers
    class ForecastIo < Handler
      namespace 'forecast_io'

      def self.default_config(config)
        config.api_key = nil
        config.api_uri = nil
      end

      route(/^!rain/, :is_it_raining)
      route(/^!geo\s+(.*)/, :geo_lookup)

      def is_it_raining(response)
        forecast = get_forecast_io_results
        response.reply 'no'
      end

      def optimistic_geo_wrapper(query)
        geocoded = nil
        result = ::Geocoder.search(query)
        if result[0]
          geocoded = result[0].data
        end
        geocoded
      end

      def geo_lookup(query)
        geocoded = optimistic_geo_wrapper query
        Location.new(
            geocoded['formatted_address'],
            geocoded['geometry']['location']['lat'],
            geocoded['geometry']['location']['long']
        )
      end

      # Wrapped for testing.
      def gimme_some_weather(url)
        HTTParty.get url
      end

      def get_forecast_io_results(query = '45.5252,-122.6751')
        if ! config.api_uri or ! config.api_key
          print "Configuration missing!  '#{config.api_uri}' '#{config.api_key}'"
        end
        # gps_coords, long_name = get_gps_coords query
        url = config.api_uri + config.api_key + '/' + query
        # puts url
        forecast = gimme_some_weather url
        # forecast['long_name'] = long_name   # Hacking the location into the hash.
        forecast
      end

    end

    Lita.register_handler(ForecastIo)
  end
end
