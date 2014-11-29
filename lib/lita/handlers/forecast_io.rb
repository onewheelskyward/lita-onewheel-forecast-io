require 'geocoder'
require 'httparty'
require 'magic_eightball'
require_relative 'location'

module Lita
  module Handlers
    class ForecastIo < Handler
      namespace 'forecast_io'
      REDIS_KEY = 'forecast_io'
      config :api_key
      config :api_uri

      route(/^!rain\s*(.*)/, :is_it_raining)
      route(/^!geo\s+(.*)/, :geo_lookup)

      def is_it_raining(response)
        Lita.logger.debug response.matches[0][0] # this shit's weird
        geocoded = geo_lookup response.user, response.matches[0][0]
        forecast = get_forecast_io_results response.user, geocoded
        reply = nil

        case forecast['currently']['precipProbability']
          when 0..0.2
            reply = MagicEightball.reply :no
          when 0.201..0.7
            reply = MagicEightball.reply :maybe
          when 0.701..1
            reply = MagicEightball.reply :yes
        end

        response.reply reply
      end

      # Geographical stuffs
      # Now with moar caching!
      def optimistic_geo_wrapper(query)
        Lita.logger.debug 'Optimisically geo wrapping!'
        geocoded = nil
        result = ::Geocoder.search(query)
        Lita.logger.debug "Geocoder result: '#{result.inspect}'"
        if result[0]
          geocoded = result[0].data
        end
        geocoded
      end

      def geo_lookup(user, query)
        Lita.logger.debug "Performing geolookup for '#{user.name}' for '#{query}'"
        if query.empty?
          Lita.logger.debug "No query specified, pulling from redis #{REDIS_KEY}, #{user.name}"
          geocoded = JSON.parse(redis.hget(REDIS_KEY, user.name))
          Lita.logger.debug "Cached location: #{geocoded.inspect}"
        end

        Lita.logger.debug "q & g #{query.inspect} #{geocoded.inspect}"
        if query.empty? and geocoded.nil?
          query = 'Portland, OR'
        end

        unless geocoded
          Lita.logger.debug "Redis hget failed, performing lookup for #{query}"
          geocoded = optimistic_geo_wrapper query
          Lita.logger.debug "Geolocation found.  '#{geocoded.inspect}' failed, performing lookup"
          redis.hset(REDIS_KEY, user.name, geocoded.to_json)
        end

        Lita.logger.debug "geocoded: '#{geocoded}'"

        loc = Location.new(
            geocoded['formatted_address'],
            geocoded['geometry']['location']['lat'],
            geocoded['geometry']['location']['lng']
        )

        Lita.logger.debug "loc: '#{loc}'"

        loc
      end

      # Wrapped for testing.  You know, when I get around to it.
      def gimme_some_weather(url)
        HTTParty.get url
      end

      def get_forecast_io_results(user, location)
        if ! config.api_uri or ! config.api_key
          Lita.logger.error "Configuration missing!  '#{config.api_uri}' '#{config.api_key}'"
        end
        # gps_coords, long_name = get_gps_coords query
        uri = config.api_uri + config.api_key + '/' + "#{location.latitude},#{location.longitude}"
        Lita.logger.debug uri
        # puts url
        forecast = gimme_some_weather uri
        # forecast['long_name'] = long_name   # Hacking the location into the hash.
        Lita.logger.debug forecast.inspect
        forecast
      end

    end

    Lita.register_handler(ForecastIo)
  end
end
