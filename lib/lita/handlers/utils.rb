require 'geocoder'
module ForecastIo
  module Utils
    REDIS_KEY = 'forecast_io'

    # Generate the JWT for weatherkit's restapi
    # https://developer.apple.com/documentation/weatherkitrestapi/request_authentication_for_weatherkit_rest_api
    def jwt_it_down(stuff)
      # Construct a developer token as a JSON object with a header that contains the following information:
      #
      # alg
      # The algorithm with which to sign the token. Set the value to ES256.
      #
      # kid
      # A 10-character key identifier you obtain from your developer account.
      #
      # id
      # An identifier that consists of your 10-character Team ID and Service ID, separated by a period.

      # In the claims payload of the token, include the following:
      #
      # iss
      # The issuer claim key. This value is your 10-character Team ID from your developer account.
      #
      # iat
      # The issued-at claim key. This value indicates the time at which the token was generated. The value is the number of seconds since epoch in Universal Coordinated Time.
      #
      # exp
      # The expiration time claim key. This value indicates the time after which the token is not accepted by the server. The value is the number of seconds since epoch in Universal Coordinated Time.
      #
      # sub
      # The subject public claim key. This value is your registered Service ID.
    end


    # Return an eightball response based on the current chance of rain.
    # If it's snowing, it's a hard no.
    def is_it_raining(response)
      geocoded = geo_lookup response.user, response.match_data[1]
      forecast = get_forecast_io_results response.user, geocoded

      response.reply get_eightball_response get_chance_of('rain', forecast['currently'])
    end

    # Return an eightball response based on the current chance of snow.
    # If it's raining, it's a hard no.
    def is_it_snowing(response)
      geocoded = geo_lookup response.user, response.match_data[1]
      forecast = get_forecast_io_results response.user, geocoded

      response.reply get_eightball_response get_chance_of('snow', forecast['currently'])
    end

    def get_eightball_response(chance)
      case chance
        when 0..0.2
          MagicEightball.reply :no
        when 0.201..0.7
          MagicEightball.reply :maybe
        when 0.701..1
          MagicEightball.reply :yes
      end
    end

    def get_chance_of(rain_or_snow, currently)
      # This is a fallthrough so we'll reply no to rain if it's snowing, and vice versa.
      chance = 0

      if currently['precipType'] == rain_or_snow    # If we match the specified string ['rain', 'snow']
        chance = currently['precipProbability']     # Set the probability for 8-ball reckoning.
      end

      chance    # Probably superfluous.
    end

    # Geographical stuffs
    # Now with moar caching!
    def optimistic_geo_wrapper(query, geocoder_key)
      Lita.logger.debug "Optimistically geo wrapping #{query}!"
      ::Geocoder.configure(
          :api_key => geocoder_key
      )
      geocoded = nil

      result = ::Geocoder.search(query)
      Lita.logger.debug "Geocoder result: '#{result.inspect}'"
      if result[0]
        geocoded = result[0].data
      end
      geocoded
    end

    # Perform a geocoder lookup based on a) the query or b) the user's serialized state.
    # If neither of those exist, default to config location.
    def geo_lookup(user, query, persist = true)
      Lita.logger.debug "Performing geolookup for '#{user.name}' for '#{query}'"

      geocoded = nil

      # I don't know why it thinks 97222 is in france
      # if !query.nil? and query.length == 5 and query.to_i >= 10000 and query.to_i <= 99999
      #   Lita.logger.debug "Post-pending usa to #{query}"
      #   query += ', usa'
      # end

      if query.nil? or query.empty?
        Lita.logger.debug "No query specified, pulling from redis '#{REDIS_KEY}', '#{user.name}'"
        serialized_geocoded = redis.hget(REDIS_KEY, user.name)
        unless serialized_geocoded == 'null' or serialized_geocoded.nil?
          if serialized_geocoded[/^http/]
            query = serialized_geocoded
          else
            geocoded = JSON.parse(serialized_geocoded)
            if geocoded['latitude'].nil?
              geocoded = nil
            end
          end

          Lita.logger.debug "Cached location: #{geocoded.inspect}"
        end
      end

      query = (query.nil?)? config.default_location.to_s : query
      Lita.logger.debug "q & g #{query.inspect} #{geocoded.inspect}"

      if query[/^http/] or (!geocoded.nil? and geocoded.key? 'geo') # For now this is aaronpk's loc
        Lita.logger.debug "Getting location from #{query}"
        resp = JSON.parse(RestClient.get query)

        locality = ''
        if resp['geo']
          locality = resp['geo']['locality']
        end

        geocoded = optimistic_geo_wrapper locality, config.geocoder_key

        # loc = Location.new(
        #     locality,
        #     resp['location']['latitude'],
        #     resp['location']['longitude']
        # )

        if persist
          redis.hset(REDIS_KEY, user, query)
        end

      else

        unless geocoded
          if query.empty?
            query = 'Portland,or'
          end

          uri = "https://atlas.p3k.io/api/geocode?input=#{URI.encode_www_form_component query}"
          Lita.logger.debug "Redis hget failed, performing lookup for #{query} on #{uri}"
          # geocoded = optimistic_geo_wrapper query, config.geocoder_key
          # Catch network errors here
          begin
            geocoded = JSON.parse RestClient.get(uri)
          rescue RuntimeError => e
            puts e
          end

          Lita.logger.debug "Geolocation found.  '#{geocoded.inspect}' failed, performing lookup"
          if persist
            redis.hset(REDIS_KEY, user.name, geocoded.to_json)
          end
        end
      end

      Lita.logger.debug "best_name: #{geocoded['best_name']}"
      Lita.logger.debug "display_name: #{geocoded['display_name']}"
      Lita.logger.debug "formatted_address: #{geocoded['formatted_address']}"
      if geocoded['full_name']
        loc = Location.new(
            geocoded['full_name'],
            geocoded['latitude'],
            geocoded['longitude'])
      elsif geocoded['lon']
        loc = Location.new(
            "#{geocoded['address']['city']}, #{geocoded['address']['state']}",
            geocoded['lat'],
            geocoded['lon'])
      else
        loc = Location.new(
            geocoded['formatted_address'],
            geocoded['geometry']['location']['lat'],
            geocoded['geometry']['location']['lng'])
      end

      Lita.logger.debug "geocoded: '#{geocoded}'"
      Lita.logger.debug "loc: '#{loc}'"

      loc
    end

    # Wrapped for testing.
    def gimme_some_weather(url)
      # HTTParty.get url
      response = RestClient.get(url)
      JSON.parse(response.to_str)
    end

    # def set_scale(user)
    #   key = user.name + '-scale'
    #   Lita.logger.debug "set_scale key: #{key}"
    #   if scale = redis.hget(REDIS_KEY, key)
    #     Lita.logger.debug "set_scale retrieved scale: #{scale}"
    #     @scale = scale
    #   end
    # end

    def get_scale(user)
      key = user.name + '-scale'
      Lita.logger.debug "get_scale key: #{key}"
      scale = redis.hget(REDIS_KEY, key)
      Lita.logger.debug "get_scale retrieved scale: #{scale}"
      if scale.nil?
        scale = 'f'
      end
      Lita.logger.debug "set_scale setting @scale to: #{scale}"
      @scale = scale
      scale
    end

    def get_windows(user)
      key = user.name + '-windows'
      windows = redis.hget(REDIS_KEY, key)
      if windows.nil?
        windows = 25
      end
      windows
    end

    def check_and_set_scale(key, user_requested_scale)
      persisted_scale = redis.hget(REDIS_KEY, key)

      if %w(c f k).include? user_requested_scale
        scale_to_set = user_requested_scale
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

      reply
    end

    def check_and_set_windows(user, user_requested_windows)
      key = user.name + '-windows'
      Lita.logger.debug "Key set to #{key}"

      Lita.logger.debug "Checking redis for #{REDIS_KEY}, #{key}"
      persisted_windows = redis.hget(REDIS_KEY, key)

      if user_requested_windows.to_f > -40 and user_requested_windows.to_f < 100
        windows_to_set = user_requested_windows
      else
        # Toggle mode
        return "Nope."
      end
      scale = get_scale user

      if scale.downcase == 'f'
        windows_to_set = f_to_c windows_to_set
      end

      if persisted_windows == windows_to_set
        reply = "Windows are already set to #{get_temperature windows_to_set, scale}!"
      else
        redis.hset(REDIS_KEY, key, windows_to_set)
        reply = "Windows open temp set to #{get_temperature windows_to_set, scale}"
      end

      reply
    end


    # Time should be in the format specified here (subset of 8601)
    # https://developer.forecast.io/docs/v2#time_call
    def get_forecast_io_results(user, location, time = nil)
      if ! config.api_uri or ! config.api_key
        Lita.logger.error "Configuration missing!  '#{config.api_uri}' '#{config.api_key}'"
        raise StandardError.new('Configuration missing!')
      end
      uri = config.api_uri + config.api_key + '/' + "#{location.latitude},#{location.longitude}"
      if time
        uri += ",#{time}"
      end

      uri += "?units=si"

      Lita.logger.debug "Requesting forcast data from: #{uri}"
      get_scale(user)
      gimme_some_weather uri
    end

    def handle_geo_lookup(response)
      location = geo_lookup(response.user, response.match_data[1], persist = false)
      response.reply "#{location.latitude}, #{location.longitude}"
    end

    def forecast_text(forecast)
      forecast_str = "weather is currently #{get_temperature forecast['currently']['temperature']} " +
          "and #{forecast['currently']['summary'].downcase}.  Winds out of the #{get_cardinal_direction_from_bearing forecast['currently']['windBearing']} at #{get_speed(forecast['currently']['windSpeed'])}. "

      if forecast['minutely']
        minute_forecast = forecast['minutely']['summary'].to_s.downcase.chop
        forecast_str += "It will be #{minute_forecast}, and #{forecast['hourly']['summary'].to_s.downcase.chop}.  "
      end

      forecast_str += "There are also #{forecast['currently']['ozone'].to_s} ozones."
    end

    def fix_time(unixtime, data_offset)
      unixtime - determine_time_offset(data_offset)
    end

    def determine_time_offset(data_offset)
      system_offset_seconds = Time.now.utc_offset
      data_offset_seconds = data_offset * 60 * 60
      system_offset_seconds - data_offset_seconds
    end

    # Utility functions

    ###
    # get_colored_string
    # Returns the dot_str colored based on our range_hash.
    # range_hash is one of our color hashes, e.g. get_wind_range_colors
    # key is used to index each element in data_limited to get our value to compare with the range_hash.
    ##
    def get_colored_string(data_limited, key, dot_str, range_hash)
      color = nil
      prev_color = nil
      collect_str = ''
      colored_str = ''

      data_limited.each_with_index do |data, index|
        range_hash.keys.each do |range_hash_key|
          key.nil? ? d = data : d = data[key]
          if range_hash_key.cover? d    # Super secred cover sauce
            color = range_hash[range_hash_key]
            if index == 0
              prev_color = color
            end
          end
        end

        # If the color changed, let's update the collect_str
        unless color == prev_color
          colored_str += "\x03" + colors[prev_color].to_s + collect_str.to_s
          collect_str = ''
        end

        collect_str += dot_str[index]
        prev_color = color
      end

      # And get the last one.
      colored_str += "\x03" + colors[color] + collect_str + "\x03"
    end

    # this method lets us condense rain forcasts into smaller sets
    # it averages the values contained in a chunk of data perportionate the the limit set
    # then returns a new array of hashes containing those averaged values
    def condense_data(data, limit)
      return if limit >= data.length
      chunk_length = (data.length / limit.to_f).round
      results = []
      data.each_slice(chunk_length) do |chunk|
        chunk_results = {}
        condensed_chunk = collect_values(chunk)
        condensed_chunk.each do |k, v|
          if v[0].class == Fixnum || v[0].class == Float
            new_val = v.inject{ |sum,val| sum + val} / v.size
          elsif v[0].class == String
            new_val = v[0]
          end
          chunk_results[k] = new_val
        end
        results << chunk_results
      end
      results
    end

    # this method is simply to transform an array of hashes into a hash of arrays
    # kudos to Phrogz for the info here: http://stackoverflow.com/questions/5490952/merge-array-of-hashes-to-get-hash-of-arrays-of-values
    def collect_values(hashes)
      {}.tap{ |r| hashes.each{ |h| h.each{ |k,v| (r[k]||=[]) << v } } }
    end

    def get_dot_str(chars, data, min, differential, key)
      str = ''
      data.each do |datum|
        key.nil? ? d = datum : d = datum[key]
        percentage = get_percentage(d, differential, min)
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
        Lita.logger.error "get_dot Probably a probability problem: #{probability} should be between 0 and 1."
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
    end

    def get_temperature(temp_c, scale = 'f')
      if @scale == 'c'
        #celcius(temp_c).to_s + '°C'
        temp_c.to_s + '°C'
      elsif @scale == 'k'
        kelvin(temp_c).to_s + 'K'
      else
        fahrenheit(temp_c).to_s + '°F'
      end
    end

    def get_speed(speed_metric)
      if @scale == 'f'
        miles(speed_metric).to_s + ' mph'
      else
        speed_metric.to_s + ' kph'
      end
    end

    def get_wind_speed(speed_metric)
      if @scale == 'f'
        miles(speed_metric.to_i * 3.6).round(2).to_s + ' mph'
      else
        (speed_metric.to_i * 3.6).round(2).to_s + ' kph'
      end
    end

    def get_distance(distance_metric, scale)
      if scale == 'f'
        miles(distance_metric).to_s + ' mi'
      else
        distance_metric.to_s + ' km'
      end
    end

    def get_accumulation(accum_mm)
      # if @scale == 'c' or @scale == 'k'
        accum_mm.to_f.round(0).to_s + 'mm'
      # else
      #   inches_from_mm(accum_mm).to_s + 'in'
      # end
    end

    def get_humidity(humidity_decimal)
      (humidity_decimal * 100).round(0).to_s + '%'
    end

    def celcius(degrees_c)
      #(0.5555555556 * (degrees_c.to_f - 32)).round(2)
      degrees_c.to_f.round(2)
    end

    def kelvin(degrees_c)
      #((degrees_c.to_f + 459.67) * 5/9).round(2)
      (degrees_c.to_f + 459.67).round(2)
    end

    def fahrenheit(degrees_c)
      ((degrees_c.to_f * 9/5) + 32).round(2)
    end

    def f_to_c(degrees_f)
      (degrees_f.to_f - 32) * 5/9.round(2)
    end

    def c_to_f(degrees_c)
      (degrees_c.to_f * 9 / 5) + 32.round(2)
    end

    def inches_from_mm(dist_mm)
      (dist_mm.to_f * 0.0393701).round(1)
    end

    def kilometers(miles)
      (miles * 1.6).round(2)
    end

    def miles(kilometers)
      (kilometers / 1.6).round(2)
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

    # This is a little weird, because the arrows are 180° rotated.  That's because the wind bearing is "out of the N" not "towards the N".
    def ansi_wind_arrows
      case robot.config.robot.adapter
        when :slack
          {'N'  => ':arrow_down:',
           'NE' => ':arrow_lower_left:',
           'E'  => ':arrow_left:',
           'SE' => ':arrow_upper_left:',
           'S'  => ':arrow_up:',
           'SW' => ':arrow_upper_right:',
           'W'  => ':arrow_right:',
           'NW' => ':arrow_lower_right:'
          }
        else
          {'N'  => '↓',
           'NE' => '↙',
           'E'  => '←',
           'SE' => '↖',
           'S'  => '↑',
           'SW' => '↗',
           'W'  => '→',
           'NW' => '↘'
          }
      end
    end

    def ascii_wind_arrows
      { 'N'  => 'v',
        'NE' => ',',
        'E'  => '<',
        'SE' => "\\",
        'S'  => '^',
        'SW' => '/',
        'W'  => '>',
        'NW' => '.'
      }
    end

    # A bit optimistic, but I really like the Cs.
    def get_other_scale(scale)
      if scale.downcase == 'c'
        'f'
      else
        'c'
      end
    end


    def make_fire(dot_str, maxtemps)
      maxtemps.each_with_index do |t, i|
        if t.to_f > 38.5
          dot_str[i] = "🔥"
        end
      end
      dot_str
    end

    # Turn intensity into a string.
    # intensity is like a 4 decimal float, we only care about the first couple.
    def get_intensity_str(pintensity)
      pintense_str = 'low'
      case pintensity * 100
      # when 0..20 then pintense_str = "low"
      when 21..50 then pintense_str = "moderate"
      when 51..999 then pintense_str = "hide ya pets hide ya kids"
      end
      pintense_str
    end

  end
end
