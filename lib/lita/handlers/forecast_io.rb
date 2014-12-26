require 'geocoder'
require 'rest_client'
require 'magic_eightball'
require_relative 'location'

module Lita
  module Handlers
    class ForecastIo < Handler
      REDIS_KEY = 'forecast_io'
      config :api_key
      config :api_uri
      config :colors

      # Temperature routes
      route(/^!ansitemp\s*(.*)/i, :handle_irc_ansitemp)
      route(/^!dailytemp\s*(.*)/i, :handle_irc_daily_temp)
      route(/^!7day\s*(.*)/i, :handle_irc_seven_day)
      route(/^!weekly\s*(.*)/i, :handle_irc_seven_day)

      # General forecast routes
      route(/^!forecastallthethings\s*(.*)/i, :handle_irc_all_the_things)
      route(/^!forecast\s*(.*)/i, :handle_irc_forecast)
      route(/^!weather\s*(.*)/i, :handle_irc_forecast)
      route(/^!condi*t*i*o*n*s*\s*(.*)/i, :handle_irc_conditions)

      # One-offs
      route(/^!rain\s*(.*)/i, :is_it_raining)
      route(/^!geo\s+(.*)/i, :geo_lookup)
      route(/^!alerts\s*(.*)/i, :handle_irc_alerts)

      # State Commands
      route(/^!set scale (c|f)/i, :handle_irc_set_scale)
      route(/^!set scale$/i, :handle_irc_set_scale)

      # Humidity
      route(/^!ansihumidity\s*(.*)/i, :handle_irc_ansi_humidity)
      route(/^!dailyhumidity\s*(.*)/i, :handle_irc_daily_humidity)

      # Rain related.  Where we all started.
      route(/^!ansisnow\s*(.*)/i, :handle_irc_ansirain)
      route(/^!ansirain\s*(.*)/i, :handle_irc_ansirain)
      route(/^!dailyrain\s*(.*)/i, :handle_irc_daily_rain)
      route(/^!weeklyrain\s*(.*)/i, :handle_irc_seven_day_rain)
      route(/^!7dayrain\s*(.*)/i, :handle_irc_seven_day_rain)
      route(/^!ansiintensity\s*(.*)/i, :handle_irc_ansirain_intensity)

      # don't start singing.
      route(/^!sunrise\s*(.*)/i, :handle_irc_sunrise)
      route(/^!sunset\s*(.*)/i, :handle_irc_sunset)
      route(/^!ansisun\s*(.*)/i, :handle_irc_ansisun)
      # Mun!

      # Wind
      route(/^!ansiwind\s*(.*)/i, :handle_irc_ansiwind)
      route(/^!dailywind\s*(.*)/i, :handle_irc_daily_wind)

      # Cloud cover
      route(/^!ansicloud\s*(.*)/i, :handle_irc_ansicloud)

      # oooOOOoooo
      route(/^!ansiozone\s*(.*)/i, :handle_irc_ansiozone)

      # Pressure
      route(/^!ansipressure\s*(.*)/i, :handle_irc_ansi_pressure)
      route(/^!ansibarometer\s*(.*)/i, :handle_irc_ansi_pressure)
      route(/^!dailypressure\s*(.*)/i, :handle_irc_daily_pressure)
      route(/^!dailybarometer\s*(.*)/i, :handle_irc_daily_pressure)

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
          0.71..1    => :yellow
        }
      end

      def get_humidity_range_colors
        {   0..0.12    => :blue,
            0.13..0.25 => :purple,
            0.26..0.38 => :teal,
            0.39..0.5  => :aqua,
            0.51..0.63 => :yellow,
            0.64..0.75 => :orange,
            0.76..0.88 => :red,
            0.89..1    => :pink,
        }
      end

      def colors
        { :white  => '00',
          :black  => '01',
          :blue   => '02',
          :green  => '03',
          :red    => '04',
          :brown  => '05',
          :purple => '06',
          :orange => '07',
          :yellow => '08',
          :lime   => '09',
          :teal   => '10',
          :aqua   => '11',
          :royal  => '12',
          :pink   => '13',
          :grey   => '14',
          :silver => '15'
        }
      end

      # I have no use for these yet, and yet they're handy to know.
      # def attributes
      #   { :bold       => 2.chr,
      #     :underlined => 31.chr,
      #     :underline  => 31.chr,
      #     :reversed   => 22.chr,
      #     :reverse    => 22.chr,
      #     :italic     => 22.chr,
      #     :reset      => 15.chr,
      #   }
      # end

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
        Lita.logger.debug 'Optimistically geo wrapping!'
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
            geocoded = JSON.parse(serialized_geocoded)
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

      # Wrapped for testing.
      def gimme_some_weather(url)
        # HTTParty.get url
        response = RestClient.get(url)
        JSON.parse(response.to_str)
      end

      def set_scale(user)
        key = user.name + '-scale'
        if scale = redis.hget(REDIS_KEY, key)
          @scale = scale
        end
      end

      def get_forecast_io_results(user, location)
        if ! config.api_uri or ! config.api_key
          Lita.logger.error "Configuration missing!  '#{config.api_uri}' '#{config.api_key}'"
        end
        uri = config.api_uri + config.api_key + '/' + "#{location.latitude},#{location.longitude}"
        Lita.logger.debug uri
        set_scale(user)
        forecast = gimme_some_weather uri
      end

      #-# Handlers
      def handle_irc_forecast(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' ' + forecast_text(forecast)
      end

      def handle_irc_ansirain(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' ' + ansi_rain_forecast(forecast)
      end

      def handle_irc_all_the_things(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' ' + forecast_text(forecast)
        response.reply location.location_name + ' ' + ansi_rain_forecast(forecast)
        response.reply location.location_name + ' ' + ansi_rain_intensity_forecast(forecast)
        response.reply location.location_name + ' ' + ansi_temp_forecast(forecast)
        response.reply location.location_name + ' ' + ansi_wind_direction_forecast(forecast)
        response.reply location.location_name + ' ' + do_the_sun_thing(forecast)
        response.reply location.location_name + ' ' + do_the_cloud_thing(forecast)
        response.reply location.location_name + ' ' + do_the_daily_rain_thing(forecast)
      end

      def handle_irc_ansirain_intensity(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' ' + ansi_rain_intensity_forecast(forecast)
      end

      def handle_irc_ansitemp(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' ' + ansi_temp_forecast(forecast)
      end

      def handle_irc_daily_temp(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' ' + ansi_temp_forecast(forecast, 48)
      end

      def handle_irc_conditions(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' ' + conditions(forecast)
      end

      def handle_irc_ansiwind(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' ' + ansi_wind_direction_forecast(forecast)
      end

      def handle_irc_alerts(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        alerts = get_alerts(forecast)
        response.reply alerts
      end

      def handle_irc_ansisun(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' ' + do_the_sun_thing(forecast)
      end

      def handle_irc_ansicloud(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' ' + do_the_cloud_thing(forecast)
      end

      def handle_irc_seven_day(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' ' + do_the_seven_day_thing(forecast)
      end

      def handle_irc_daily_rain(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' ' + do_the_daily_rain_thing(forecast)
      end

      def handle_irc_seven_day_rain(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' ' + do_the_seven_day_rain_thing(forecast)
      end

      def handle_irc_daily_wind(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' ' + do_the_daily_wind_thing(forecast)
      end

      def handle_irc_daily_humidity(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' ' + do_the_daily_humidity_thing(forecast)
      end

      def handle_irc_ansi_humidity(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' 48hr humidity ' + ansi_humidity_forecast(forecast)
      end

      def handle_irc_ansiozone(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' ' + do_the_ozone_thing(forecast)
      end

      def handle_irc_ansi_pressure(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' ' + do_the_pressure_thing(forecast)
      end

      def handle_irc_daily_pressure(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' ' + do_the_daily_pressure_thing(forecast)
      end

      # Todo: Too much logic.
      def handle_irc_set_scale(response)
        key = response.user.name + '-scale'
        persisted_scale = redis.hget(REDIS_KEY, key)

        if ['c','f'].include? response.matches[0][0].downcase
          scale_to_set = response.matches[0][0]
        else
          # Toggle mode
          scale_to_set = get_other_scale(persisted_scale)
        end

        if persisted_scale == scale_to_set
          reply = "Scale is already set to #{scale_to_set}!"
        else
          redis.hset(REDIS_KEY, key, scale_to_set)
          reply = "Scale set to #{scale_to_set}"
        end
        response.reply reply
      end

      def handle_irc_sunrise(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' sunrise: ' + do_the_sunrise_thing(forecast)
      end

      def handle_irc_sunset(response)
        location = geo_lookup(response.user, response.matches[0][0])
        forecast = get_forecast_io_results(response.user, location)
        response.reply location.location_name + ' sunset: ' + do_the_sunset_thing(forecast)
      end

      def forecast_text(forecast)
        minute_forecast = forecast['minutely']['summary'].to_s.downcase.chop if forecast['minutely']
        "weather is currently #{get_temperature forecast['currently']['temperature']} " +
            "and #{forecast['currently']['summary'].downcase}.  Winds out of the #{get_cardinal_direction_from_bearing forecast['currently']['windBearing']} at #{get_speed(forecast['currently']['windSpeed'])}. " +
            "It will be #{minute_forecast}, and #{forecast['hourly']['summary'].to_s.downcase.chop}.  There are also #{forecast['currently']['ozone'].to_s} ozones."
        # daily.summary
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

      def ansi_rain_intensity_forecast(forecast)
        str = do_the_rain_intensity_thing(forecast, ansi_chars, 'precipIntensity') #, 'probability', get_rain_range_colors)
        #msg.reply "|#{str}|  min-by-min rain prediction.  range |▁▃▅▇█▇▅▃▁| art by 'a-g-j' =~ s/-//g"
        "rain intensity #{(Time.now).strftime('%H:%M').to_s}|#{str}|#{(Time.now + 3600).strftime('%H:%M').to_s}"  #range |_.-•*'*•-._|
      end

      def ansi_humidity_forecast(forecast)
        do_the_humidity_thing(forecast, ansi_chars, 'humidity') #, 'probability', get_rain_range_colors)
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

        str = get_dot_str(chars, data, 0, 1, key)

        if config.colors
          str = get_colored_string(data, key, str, get_rain_range_colors)
        end
        str
      end

      def do_the_rain_intensity_thing(forecast, chars, key) #, type, range_colors = nil)
        if forecast['minutely'].nil?
          return 'No minute-by-minute data available.'
        end

        data_points = []
        data = forecast['minutely']['data']

        data.each do |datum|
          data_points.push datum[key]
        end

        str = get_dot_str(chars, data, data_points.min, data_points.max, key)

        if config.colors
          str = get_colored_string(data, key, str, get_rain_intensity_range_colors)
        end
        str
      end

      def do_the_humidity_thing(forecast, chars, key) #, type, range_colors = nil)
        data_points = []
        data = forecast['hourly']['data']

        data.each do |datum|
          data_points.push datum[key]
        end

        str = get_dot_str(chars, data, 0, 1, key)

        if config.colors
          str = get_colored_string(data, key, str, get_humidity_range_colors)
        end
        "#{get_humidity data_points.first}|#{str}|#{get_humidity data_points.last} range: #{get_humidity data_points.min}-#{get_humidity data_points.max}"
      end

      def ansi_temp_forecast(forecast, hours = 24)
        str, temperature_data = do_the_temp_thing(forecast, ansi_chars, hours)
        "#{hours} hr temps: #{get_temperature temperature_data.first.round(1)} |#{str}| #{get_temperature temperature_data.last.round(1)}  Range: #{get_temperature temperature_data.min.round(1)} - #{get_temperature temperature_data.max.round(1)}"
      end

      def do_the_temp_thing(forecast, chars, hours)
        temps = []
        data = forecast['hourly']['data'].slice(0,hours - 1)
        key = 'temperature'

        data.each_with_index do |datum, index|
          temps.push datum[key]
          break if index == hours - 1 # We only want (hours) 24hrs of data.
        end

        differential = temps.max - temps.min

        # Hmm.  There's a better way.
        dot_str = get_dot_str(chars, data, temps.min, differential, key)

        if config.colors
          dot_str = get_colored_string(data, key, dot_str, get_temp_range_colors)
        end

        return dot_str, temps
        # return dot_str, temps
      end

      def ansi_wind_direction_forecast(forecast)
        str, data = do_the_wind_direction_thing(forecast)
        "48h wind direction #{get_speed data.first}|#{str}|#{get_speed data.last} Range: #{get_speed(data.min)} - #{get_speed(data.max)}"
      end

      def do_the_wind_direction_thing(forecast, hours = 48)
        key = 'windBearing'
        data = forecast['hourly']['data'].slice(0,hours - 1)
        str = ''
        data_points = []
        # This is a little weird, because the arrows are 180° rotated.  That's because the wind bearing is "out of the N" not "towards the N".
        wind_arrows = {'N' => '↓', 'NE' => '↙', 'E' => '←', 'SE' => '↖', 'S' => '↑', 'SW' => '↗', 'W' => '→', 'NW' => '↘'}

        data.each_with_index do |datum, index|
          str += wind_arrows[get_cardinal_direction_from_bearing datum[key]]
          data_points.push datum['windSpeed']
          break if index == hours - 1 # We only want (hours) 24hrs of data.
        end

        if config.colors
          str = get_colored_string(data, 'windSpeed', str, get_wind_range_colors)
        end

        return str, data_points
      end

      def do_the_sun_thing(forecast)
        key = 'cloudCover'
        data_points = []
        data = forecast['daily']['data']

        data.each do |datum|
          data_points.push (1 - datum[key]).to_f  # It's a cloud cover percentage, so let's inverse it to give us sun cover.
          datum[key] = (1 - datum[key]).to_f      # Mod the source data for the get_dot_str call below.
        end

        differential = data_points.max - data_points.min

        str = get_dot_str(ansi_chars, data, data_points.min, differential, key)

        if config.colors
          str = get_colored_string(data, key, str, get_sun_range_colors)
        end

        "8 day sun forecast |#{str}|"
      end

      def do_the_cloud_thing(forecast)
        # O ◎ ]
        data = forecast['hourly']['data'].slice(0,23)

        str = get_dot_str(ansi_chars, data, 0, 1, 'cloudCover')

        "24h cloud cover |#{str}|"
      end

      def do_the_sunrise_thing(forecast)
        t = Time.at(fix_time(forecast['daily']['data'][0]['sunriseTime'], forecast['offset']))
        t.strftime("%H:%M:%S")
      end

      def do_the_sunset_thing(forecast)
        t = Time.at(fix_time(forecast['daily']['data'][0]['sunsetTime'], forecast['offset']))
        t.strftime("%H:%M:%S")
      end

      def fix_time(unixtime, data_offset)
        unixtime - determine_time_offset(data_offset)
      end

      def determine_time_offset(data_offset)
        system_offset_seconds = Time.now.utc_offset
        data_offset_seconds = data_offset * 60 * 60
        system_offset_seconds - data_offset_seconds
      end

      def conditions(forecast)
        temp_str, temps = do_the_temp_thing(forecast, ansi_chars, 8)
        wind_str, winds = do_the_wind_direction_thing(forecast, 8)
        rain_str, rains = do_the_rain_chance_thing(forecast, ansi_chars, 'precipProbability') # , 'probability', get_rain_range_colors

        rs = compress_string(rain_str, 4)

        sun_chance = ((1 - forecast['daily']['data'][0]['cloudCover']) * 100).round
        "#{get_temperature temps.first.round(2)} |#{temp_str}| #{get_temperature temps.last.round(2)} " + "/ #{get_speed(winds.first)} |#{wind_str}| #{get_speed(winds.last)} / #{sun_chance}% chance of sun / 60m rain |#{rs}|"
      end

      def do_the_seven_day_thing(forecast)
        mintemps = []
        maxtemps = []

        data = forecast['daily']['data']
        data.each do |day|
          mintemps.push day['temperatureMin']
          maxtemps.push day['temperatureMax']
        end

        differential = maxtemps.max - maxtemps.min
        max_str = get_dot_str(ansi_chars, data, maxtemps.min, differential, 'temperatureMax')

        differential = mintemps.max - mintemps.min
        min_str = get_dot_str(ansi_chars, data, mintemps.min, differential, 'temperatureMin')

        if config.colors
          max_str = get_colored_string(data, 'temperatureMax', max_str, get_temp_range_colors)
          min_str = get_colored_string(data, 'temperatureMin', min_str, get_temp_range_colors)
        end

        "7day high/low temps #{get_temperature maxtemps.first.to_f.round(1)} |#{max_str}| #{get_temperature maxtemps.last.to_f.round(1)} / #{get_temperature mintemps.first.to_f.round(1)} |#{min_str}| #{get_temperature mintemps.last.to_f.round(1)} Range: #{get_temperature mintemps.min} - #{get_temperature maxtemps.max}"
      end

      def do_the_seven_day_rain_thing(forecast)
        precip_type = 'rain'
        rains = []

        data = forecast['daily']['data']
        data.each do |day|
          if day['precipType'] == 'snow'
            precip_type = 'snow'
          end
          rains.push day['precipProbability']
        end

        # differential = maxtemps.max - maxtemps.min
        str = get_dot_str(ansi_chars, data, 0, 1, 'precipProbability')

        if config.colors
          str = get_colored_string(data, 'precipProbability', str, get_rain_range_colors)
        end
        
        "7day #{precip_type}s |#{str}|"
      end

      def do_the_daily_rain_thing(forecast)
        precip_type = 'rain'
        rains = []

        data = forecast['hourly']['data']
        data.each do |day|
          if day['precipType'] == 'snow'
            precip_type = 'snow'
          end
          rains.push day['precipProbability']
        end

        # differential = maxtemps.max - maxtemps.min
        str = get_dot_str(ansi_chars, data, 0, 1, 'precipProbability')

        if config.colors
          str = get_colored_string(data, 'precipProbability', str, get_rain_range_colors)
        end

        "48 hr #{precip_type}s |#{str}|"
      end

      def do_the_daily_wind_thing(forecast)
        winds = []

        data = forecast['daily']['data']
        data.each do |day|
          winds.push day['windSpeed']
        end

        # differential = maxtemps.max - maxtemps.min
        str = get_dot_str(ansi_chars, data, 0, winds.max, 'windSpeed')

        if config.colors
          str = get_colored_string(data, 'windSpeed', str, get_wind_range_colors)
        end

        "7day winds #{get_speed winds.first}|#{str}|#{get_speed winds.last} range #{get_speed winds.min}-#{get_speed winds.max}"
      end

      def do_the_daily_humidity_thing(forecast)
        humidities = []

        data = forecast['daily']['data']
        data.each do |day|
          humidities.push day['humidity']
        end

        # differential = maxtemps.max - maxtemps.min
        str = get_dot_str(ansi_chars, data, 0, 1, 'humidity')

        if config.colors
          str = get_colored_string(data, 'humidity', str, get_wind_range_colors)
        end

        "7day humidity #{get_humidity humidities.first}|#{str}|#{get_humidity humidities.last} range #{get_humidity humidities.min}-#{get_humidity humidities.max}"
      end

      def do_the_ozone_thing(forecast)
        # O ◎ ]
        data = forecast['hourly']['data']

        str = get_dot_str(ozone_chars, data, 280, 350-280, 'ozone')

        "ozones #{data.first['ozone']} |#{str}| #{data.last['ozone']} [24h forecast]"
      end

      def do_the_pressure_thing(forecast)
        # O ◎ ]
        data = forecast['hourly']['data']
        key = 'pressure'
        boiled_data = []

        data.each do |d|
          boiled_data.push d[key]
        end

        str = get_dot_str(ansi_chars, data, boiled_data.min, boiled_data.max - boiled_data.min, key)

        "pressure #{data.first[key]} hPa |#{str}| #{data.last[key]} hPa range: #{boiled_data.min}-#{boiled_data.max} hPa [48h forecast]"
      end

      def do_the_daily_pressure_thing(forecast)
        # O ◎ ]
        data = forecast['daily']['data']
        key = 'pressure'
        boiled_data = []

        data.each do |d|
          boiled_data.push d[key]
        end

        str = get_dot_str(ansi_chars, data, boiled_data.min, boiled_data.max - boiled_data.min, key)

        "pressure #{data.first[key]} hPa |#{str}| #{data.last[key]} hPa range: #{boiled_data.min}-#{boiled_data.max} hPa [8 day forecast]"
      end

      def get_alerts(forecast)
        str = ''
        forecast['alerts'].each do |alert|
          alert['description'].match /\.\.\.(\w+)\.\.\./
          str += "#{alert['uri']}\n"
        end
        str
      end

      # Utility functions
      def get_colored_string(data_limited, key, dot_str, range_hash)
        color = nil
        prev_color = nil
        collect_str = ''
        colored_str = ''

        # data_limited is an array of data points that will be stringed.
        data_limited.each_with_index do |data, index|
          range_hash.keys.each do |range_hash_key|
            if range_hash_key.cover? data[key]
              color = range_hash[range_hash_key]
              if index == 0
                prev_color = color
              end
            end
          end

          # If the color changed, let's update the collect_str
          unless color == prev_color
            colored_str += "\x03" + colors[prev_color] + collect_str
            collect_str = ''
          end

          collect_str += dot_str[index]
          prev_color = color
        end

        # And get the last one.
        colored_str += "\x03" + colors[color] + collect_str + "\x03"
        colored_str
      end

      def compress_string(str, compression_factor)
        i = 0
        rs = ''
        str.to_s.each_char do |char|
          if i % compression_factor == 0
            rs += char
          end
          i += 1
        end
        rs
      end

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

      def get_humidity(humidity_decimal)
        (humidity_decimal * 100).round(0).to_s + '%'
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

      # A bit optimistic, but I really like the Cs.
      def get_other_scale(scale)
        if scale.downcase == 'c'
          'f'
        else
          'c'
        end
      end

    end

    Lita.register_handler(ForecastIo)
  end
end
