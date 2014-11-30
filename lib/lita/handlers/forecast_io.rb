# encoding: utf-8
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
      route(/^!ansirain\s*(.*)/, :handle_irc_ansirain)

      # Constants
      def scale
        'f'
      end

      def ansi_chars
        %w[_ ▁ ▃ ▅ ▇ █]
      end

      def ozone_chars
        %w[・ o O @ ◎ ◉]
      end

      def ascii_chars
        %w[_ . - ~ * ']
      end

      def get_rain_range_colors
        { 0..0.10    => :blue,
          0.11..0.20 => :purple,
          0.21..0.30 => :teal,
          0.31..0.40 => :green,
          0.41..0.50 => :lime,
          0.51..0.60 => :aqua,
          0.61..0.70 => :yellow,
          0.71..0.80 => :orange,
          0.81..0.90 => :red,
          0.91..1    => :pink
        }
      end

      def get_rain_intensity_range_colors
        { 0..0.0050      => :blue,
          0.0051..0.0100 => :purple,
          0.0101..0.0130 => :teal,
          0.0131..0.0170 => :green,
          0.0171..0.0220 => :lime,
          0.0221..0.0280 => :aqua,
          0.0281..0.0330 => :yellow,
          0.0331..0.0380 => :orange,
          0.0381..0.0430 => :red,
          0.0431..1      => :pink
        }
      end

      def get_temp_range_colors
        # Absolute zero?  You never know.
        { -459.7..24.99 => :blue,
          25..31.99     => :purple,
          32..38        => :teal,
          38..45        => :green,
          45..55        => :lime,
          55..65        => :aqua,
          65..75        => :yellow,
          75..85        => :orange,
          85..95        => :red,
          95..159.3     => :pink
        }
      end

      def get_wind_range_colors
        {   0..3    => :blue,
            3..6    => :purple,
            6..9    => :teal,
            9..12   => :aqua,
            12..15  => :yellow,
            15..18  => :orange,
            18..21  => :red,
            21..999 => :pink,
        }
      end

      def get_sun_range_colors
        { 0..0.20    => :green,
          0.21..0.50 => :lime,
          0.51..0.70 => :orange,
          0.71..1 => :yellow
        }
      end

      # End constants

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
          serialized_geocoded = redis.hget(REDIS_KEY, user.name)
          unless serialized_geocoded.nil?
            geocoded = JSON.parse()
          end
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

      def handle_irc_ansirain(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply ansi_rain_forecast(forecast)
      end

      # ▁▃▅▇█▇▅▃▁ agj
      def ascii_rain_forecast(forecast)
        str = do_the_rain_chance_thing(forecast, ascii_chars, 'precipProbability') #, 'probability', get_rain_range_colors)
        "rain probability #{(Time.now).strftime('%H:%M').to_s}|#{str}|#{(Time.now + 3600).strftime('%H:%M').to_s}"  #range |_.-•*'*•-._|
      end

      def ansi_rain_forecast(forecast)
        str = do_the_rain_chance_thing(forecast, ansi_chars, 'precipProbability') #, 'probability', get_rain_range_colors)
        #msg.reply "|#{str}|  min-by-min rain prediction.  range |▁▃▅▇█▇▅▃▁| art by 'a-g-j' =~ s/-//g"
        "rain probability #{(Time.now).strftime('%H:%M').to_s}|#{str}|#{(Time.now + 3600).strftime('%H:%M').to_s}"  #range |_.-•*'*•-._|
      end

      def do_the_rain_chance_thing(forecast, chars, key) #, type, range_colors = nil)
        if forecast['minutely'].nil?
          return 'No minute-by-minute data available.'
        end

        data_points = []
        data = forecast['minutely']['data']

        data.each do |datum|
          data_points.push datum[key]
        end

        # if precip_type == 'snow' and type != 'intensity'
        #   chars = %w[_ ☃ ☃ ☃ ☃ ☃] # Hat tip to hallettj@#pdxtech
        # end

        str = get_dot_str(chars, data, data_points.min, 1, key)

        # if range_colors
        #   str = get_colored_string(data, key, str, range_colors)
        # end

        return str
      end

      # Utility functions
      def get_dot_str(chars, data, min, differential, key)
        str = ''
        data.each do |datum|
          percentage = get_percentage(datum[key], differential, min)
          str += get_dot(percentage, chars)
        end
        str
      end

      def get_percentage(number, differential, min)
        if differential == 0
          percentage = number
        else
          percentage = (number.to_f - min) / (differential)
        end
        percentage
      end

      # °℃℉
      def get_dot(probability, char_array)
        if probability < 0 or probability > 1
          return '?'
        end

        if probability == 0
          return char_array[0]
        elsif probability <= 0.10
          return char_array[1]
        elsif probability <= 0.25
          return char_array[2]
        elsif probability <= 0.50
          return char_array[3]
        elsif probability <= 0.75
          return char_array[4]
        elsif probability <= 1.00
          return char_array[5]
        end
        #if probability == 0
        #  return Format(:blue, char_array[0])
        #elsif probability <= 0.10
        #  return Format(:purple, char_array[1])
        #elsif probability <= 0.25
        #  return Format(:teal, char_array[2])
        #elsif probability <= 0.50
        #  return Format(:yellow, char_array[3])
        #elsif probability <= 0.75
        #  return Format(:orange, char_array[4])
        #elsif probability <= 1.00
        #  return Format(:red, char_array[5])
        #end

      end

      def determine_intensity(query)
        if query =~ /^intensity/
          query = query.gsub /^intensity\s*/, ''
          key = 'precipIntensity'
        else
          key = 'precipProbability'
        end
        return query, key
      end

      def get_temperature(temp_f)
        if @scale == 'c'
          celcius(temp_f).to_s + '°C'
        else
          temp_f.to_s + '°F'
        end
      end

      def get_speed(speed_imperial)
        if @scale == 'c'
          kilometers(speed_imperial).to_s + ' kph'
        else
          speed_imperial.to_s + ' mph'
        end
      end

      def celcius(degrees_f)
        (0.5555555556 * (degrees_f.to_f - 32)).round(2)
      end

      def kilometers(speed_imperial)
        (speed_imperial * 1.6).round(2)
      end

      def get_cardinal_direction_from_bearing(bearing)
        case bearing
          when 0..25
            'N'
          when 26..65
            'NE'
          when 66..115
            'E'
          when 116..155
            'SE'
          when 156..205
            'S'
          when 206..245
            'SW'
          when 246..295
            'W'
          when 296..335
            'NW'
          when 336..360
            'N'
        end
      end

    end

    Lita.register_handler(ForecastIo)
  end
end
