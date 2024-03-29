require 'tzinfo'

module ForecastIo
  module Forecasts
    def ascii_rain_forecast(forecast)
      (str, precip_type) = do_the_rain_chance_thing(forecast, ascii_chars, 'precipProbability')
      max = get_max_by_data_key(forecast, 'minutely', 'precipProbability')
      agg = get_max_by_data_key(forecast, 'minutely', 'precipIntensity')
      "1hr #{precip_type} probability #{(Time.now).strftime('%H:%M').to_s}|#{str}|#{(Time.now + 3600).strftime('%H:%M').to_s} max #{(max.to_f * 100).round(2)}%, #{get_accumulation agg} accumulation"
    end

    def next_rain_forecast(forecast)
      (rain_str, precip_type) = do_the_next_rain_thing(forecast)
      rain_str
    end

    def ansi_rain_forecast(forecast)
      (str, precip_type) = do_the_rain_chance_thing(forecast, ansi_chars, 'precipProbability') #, 'probability', get_rain_range_colors)
      max = get_max_by_data_key(forecast, 'minutely', 'precipProbability')
      agg = get_avg_by_data_key(forecast, 'minutely', 'precipIntensity')
      "1hr #{precip_type} probability #{(Time.now).strftime('%H:%M').to_s}|#{str}|#{(Time.now + 3600).strftime('%H:%M').to_s} max #{(max.to_f * 100).round(2)}%, #{get_accumulation agg} accumulation"
    end

    def ansi_rain_intensity_forecast(forecast)
      (str, precip_type) = do_the_rain_intensity_thing(forecast, ansi_chars, 'precipIntensity') #, 'probability', get_rain_range_colors)
      agg = get_max_by_data_key(forecast, 'minutely', 'precipIntensity')
      "1hr #{precip_type} intensity #{(Time.now).strftime('%H:%M').to_s}|#{str}|#{(Time.now + 3600).strftime('%H:%M').to_s}, #{get_accumulation agg} accumulation"
    end

    def ansi_humidity_forecast(forecast)
      do_the_humidity_thing(forecast, ansi_chars, 'humidity') #, 'probability', get_rain_range_colors)
    end

    def get_max_by_data_key(forecast, key, datum)
      unless forecast[key].nil?
        data_points = []
        forecast[key]['data'].each do |data_point|
          data_points.push data_point[datum]
        end
        data_points.max
      end
    end

    def get_sum_by_data_key(forecast, key, datum)
      unless forecast[key].nil?
        data_points = []
        forecast[key]['data'].each do |data_point|
          # Lita.logger.debug data_point
          data_points.push data_point[datum]
        end
        data_points.sum
      end
    end

    def get_avg_by_data_key(forecast, key, datum)
      unless forecast[key].nil?
        data_points = []
        forecast[key]['data'].each do |data_point|
          data_points.push data_point[datum].to_f
        end
        avg = data_points.sum / data_points.length

      end
    end

    def get_min_by_data_key(forecast, key, datum)
      unless forecast[key].nil?
        data_points = []
        forecast[key]['data'].each do |data_point|
          data_points.push data_point[datum]
        end
        data_points.min
      end
    end

    # Honestly don't remember where I used this.
    # def get_aggregate_by_data_key(forecast, key, datum)
    #   unless forecast[key].nil?
    #     sum = 0
    #     forecast[key]['data'].each do |data_point|
    #       Lita.logger.debug "Adding #{data_point[datum]} to #{sum}"
    #       sum += data_point[datum].to_f
    #     end
    #     sum.round(3)
    #   end
    # end

    def do_the_rain_chance_thing(forecast, chars, key, use_color = config.colors, minute_limit = nil)
      if forecast['minutely'].nil?
        return 'No minute-by-minute data available.'
      end

      i_can_has_snow = false
      data_points = []
      data = forecast['minutely']['data']

      data.each do |datum|
        data_points.push datum[key]
        if datum['precipType'] == 'snow'
          i_can_has_snow = true
        end
      end

      if minute_limit
        data = condense_data(data, minute_limit)
      end

      str = get_dot_str(chars, data, 0, 1, key)

      if i_can_has_snow
        data.each_with_index do |datum, index|
          if datum['precipType'] == 'snow'
            str[index] = get_snowman config
          end
        end
      end

      if use_color
        str = get_colored_string(data, key, str, get_rain_range_colors)
      end

      precip_type = i_can_has_snow ? 'snow' : 'rain'

      return str, precip_type
    end

    def do_the_rain_intensity_thing(forecast, chars, key) #, type, range_colors = nil)
      if forecast['minutely'].nil?
        return 'No minute-by-minute data available.'  # The "Middle of Nowhere" case.
      end

      i_can_has_snow = false
      data_points = []
      data = forecast['minutely']['data']

      data.each do |datum|
        data_points.push datum[key]
        if datum['precipType'] == 'snow'
          i_can_has_snow = true
        end
      end

      # Fixed range graph- 0-0.11.
      str = get_dot_str(chars, data, 0, 10, key)

      if config.colors
        str = get_colored_string(data, key, str, get_rain_intensity_range_colors)
      end

      precip_type = i_can_has_snow ? 'snow' : 'rain'

      return str, precip_type
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

    def do_the_next_rain_thing(forecast)
      i_can_has_snow = false
      rain_time = nil
      mindata = forecast['minutely']['data']
      data = forecast['hourly']['data']
      dailydata = forecast['daily']['data']

      min_start = nil
      min_end = nil
      raintensity = 0

      mindata.each do |m|
        if min_start.nil? and m['precipProbability'].to_f >= 0.20
          min_start = m['time']
        end
        if not min_start.nil? and m['precipProbability'].to_f < 0.20
          min_end = m['time']
          break
        end
        raintensity = m['precipIntensity'].to_f if m['precipIntensity'].to_f > raintensity
      end

      pintense_str = get_intensity_str(raintensity)

      # If rain is starting/ending this hour, do the minute detail thing
      unless min_start.nil?
        t1 = Time.now.to_i
        rain_start = min_start - t1
        rain_time = ''

        if rain_start < 0
          rain_time = "for now, "
        else
          rain_time = "in #{(rain_start) / 60} minutes, "
        end

        if min_end.nil?
          rain_time += "ending in a long while."
        else
          rain_time += "ending in about #{(min_end - t1) / 60} minutes."
        end

        rain_time += "  Max intensity is #{pintense_str}."
      end

      # No minutes, let's step through hourly.
      if min_start.nil?
        data.each do |datum|
          if datum['precipType'] == 'snow'
            i_can_has_snow = true
          end
          if datum['precipProbability'].to_f >= 0.2
            rain_time = datum['time']
            raintensity = datum['precipIntensity']
            break
          end
        end

        rain_time = rain_time - Time.now.to_i
        rain_time = rain_time / 60 / 60

        if rain_time <= 0
          rain_time = "now."
        else
          rain_time = "#{rain_time} #{rain_time.to_i == 1? 'hour' : 'hours'}"
        end
        rain_time = "in about #{rain_time}"
      end

      # if min_end.nil?
      #   data.each do |datum|
      #     if datum['precipProbability'].to_f < 0.2
      #       rain_time = datum['time']
      #       break
      #     end
      #   end
      #
      #   rain_time = rain_time - Time.now.to_i
      #   rain_time = rain_time / 60 / 60
      #
      #   rain_time = "#{rain_time} #{rain_time.to_i == 1? 'hour' : 'hours'}"
      # end

      return rain_time, i_can_has_snow
    end

    def ansi_temp_forecast(forecast, hours = 24)
      str, temperature_data = do_the_temp_thing(forecast, 'temperature', ansi_chars, hours)
      resp = "#{hours} hr temps: #{get_temperature temperature_data.first.round(1)} "
      resp += "(feels like #{get_temperature get_current_apparent_temp(forecast)}) |#{str}| "
      resp += "#{get_temperature temperature_data.last.round(1)}  Range: "
      resp += "#{get_temperature temperature_data.min.round(1)} - #{get_temperature temperature_data.max.round(1)}"
    end

    def ansi_temp_apparent_forecast(forecast, hours = 24)
      str, temperature_data = do_the_temp_thing(forecast, 'apparentTemperature', ansi_chars, hours)
      "#{hours} hr apparent temps: #{get_temperature temperature_data.first.round(1)} |#{str}| #{get_temperature temperature_data.last.round(1)}  Range: #{get_temperature temperature_data.min.round(1)} - #{get_temperature temperature_data.max.round(1)}"
    end

    def ansi_windchill_forecast(forecast, hours = 24)
      str, temperature_data = do_the_windchill_temp_thing(forecast, ansi_chars, hours)
      "#{hours} hr windchill temps: #{get_temperature temperature_data.first.round(1)} |#{str}| #{get_temperature temperature_data.last.round(1)}  Range: #{get_temperature temperature_data.min.round(1)} - #{get_temperature temperature_data.max.round(1)}"
    end

    def ascii_temp_forecast(forecast, hours = 24)
      str, temperature_data = do_the_temp_thing(forecast, 'temperature', ascii_chars, hours)
      resp = "#{hours} hr temps: #{get_temperature temperature_data.first.round(1)} "
      resp += "(feels like #{get_temperature get_current_apparent_temp(forecast)}) "
      resp += "|#{str}| #{get_temperature temperature_data.last.round(1)}  Range: "
      resp += "#{get_temperature temperature_data.min.round(1)} - #{get_temperature temperature_data.max.round(1)}"
    end

    def do_the_temp_thing(forecast, key, chars, hours)
      temps = []
      data = forecast['hourly']['data'].slice(0,hours - 1)

      data.each_with_index do |datum, index|
        temps.push datum[key]
        break if index == hours - 1 # We only want (hours) 24hrs of data.
      end

      differential = temps.max - temps.min

      # Hmm.  There's a better way.
      dot_str = get_dot_str(chars, data, temps.min, differential, key)

      dot_str = make_fire dot_str, temps

      if config.colors
        dot_str = get_colored_string(data, key, dot_str, get_temp_range_colors)
      end

      return dot_str, temps
    end

    def do_the_windchill_temp_thing(forecast, chars, hours)
      temps = []
      wind = []
      data = forecast['hourly']['data'].slice(0,hours - 1)
      key = 'temperature'
      wind_key = 'windSpeed'

      data.each_with_index do |datum, index|
        temps.push calculate_windchill(datum[key], datum[wind_key])
        break if index == hours - 1 # We only want (hours) 24hrs of data.
      end

      differential = temps.max - temps.min

      # Hmm.  There's a better way.
      dot_str = get_dot_str(chars, data, temps.min, differential, key)

      if config.colors
        dot_str = get_colored_string(data, key, dot_str, get_temp_range_colors)
      end

      return dot_str, temps
    end

    # Temp must be C.
    def calculate_windchill(temp_c, wind)
      #temp_f = fahrenheit(temp_c)
      #35.74 + (0.6215 * temp_f) - (35.75 * wind ** 0.16) + (0.4275 * temp_f * wind ** 0.16)
      13.12 + (0.6215 * temp_c) - (11.37 * (wind ** 0.16)) + (0.3965 * (temp_c * (wind ** 0.16)))
    end

    def ansi_wind_direction_forecast(forecast)
      str, wind_speed, wind_gust = do_the_wind_direction_thing(forecast, ansi_wind_arrows)
      "48h wind direction #{get_wind_speed wind_speed.first}|#{str}|#{get_wind_speed wind_speed.last} Range: #{get_wind_speed(wind_speed.min)} - #{get_wind_speed(wind_speed.max)}, gusting to #{get_wind_speed wind_gust.max}"
    end

    def ascii_wind_direction_forecast(forecast)
      str, wind_speed, wind_gust = do_the_wind_direction_thing(forecast, ascii_wind_arrows)
      "48h wind direction #{get_speed wind_speed.first}|#{str}|#{get_wind_speed wind_speed.last} Range: #{get_wind_speed(wind_speed.min)} - #{get_wind_speed(wind_speed.max)}, gusting to #{get_wind_speed wind_gust.max}"
    end

    def do_the_wind_direction_thing(forecast, wind_arrows, hours = 48)
      key = 'windBearing'
      data = forecast['hourly']['data'].slice(0,hours - 1)
      str = ''
      data_points = []
      gust_data = []

      data.each_with_index do |datum, index|
        wind_arrow_index = get_cardinal_direction_from_bearing(datum[key])
        str << wind_arrows[wind_arrow_index].to_s
        data_points.push datum['windSpeed']
        gust_data.push datum['windGust']
        break if index == hours - 1 # We only want (hours) of data.
      end

      if config.colors
        str = get_colored_string(data, 'windSpeed', str, get_wind_range_colors)
      end

      return str, data_points, gust_data
    end

    def do_the_sun_thing(forecast, chars)
      key = 'cloudCover'
      data_points = []
      data = forecast['hourly']['data']
      sun_mod_data = []

      data.each do |datum|
        data_points.push (1 - datum[key]).to_f  # It's a cloud cover percentage, so let's inverse it to give us sun cover.
        sun_mod_data << {key => (1 - datum[key]).to_f}      # Mod the source data for the get_dot_str call below.
      end

      differential = data_points.max - data_points.min

      str = get_dot_str(chars, sun_mod_data, data_points.min, differential, key)

      if config.colors
        str = get_colored_string(sun_mod_data, key, str, get_sun_range_colors)
      end

      max = 1 - get_min_by_data_key(forecast, 'hourly', key)

      "48hr sun forecast |#{str}| max #{(max * 100).to_i}%"
    end

    def do_the_daily_sun_thing(forecast, chars)
      key = 'cloudCover'
      data_points = []
      data = forecast['daily']['data']

      data.each do |datum|
        data_points.push (1 - datum[key]).to_f  # It's a cloud cover percentage, so let's inverse it to give us sun cover.
        datum[key] = (1 - datum[key]).to_f      # Mod the source data for the get_dot_str call below.
      end

      differential = data_points.max - data_points.min

      str = get_dot_str(chars, data, data_points.min, differential, key)

      if config.colors
        str = get_colored_string(data, key, str, get_sun_range_colors)
      end

      max = 1 - get_min_by_data_key(forecast, 'daily', key)

      "8 day sun forecast |#{str}| max #{(max * 100).to_i}%"
    end

    def do_the_cloud_thing(forecast, chars)
      # O ◎ ]
      data = forecast['hourly']['data'].slice(0,23)

      max = 0
      min = 1
      data.each do |datum|
        if datum['cloudCover'] > max
          max = datum['cloudCover']
        end
        if datum['cloudCover'] < min
          min = datum['cloudCover']
        end
      end
      str = get_dot_str(chars, data, 0, 1, 'cloudCover')

      "24h cloud cover |#{str}| range #{min * 100}% - #{max * 100}%"
    end

    def do_the_fog_thing(forecast, chars)
      key = 'visibility'
      data_points = []
      data = forecast['hourly']['data'].slice(0,23)

      cap = 16
      max = 0
      min = 16

      data.each do |datum|
        datum[key] = 16 if datum[key] > 16

        max = datum[key] if datum[key] > max
        min = datum[key] if datum[key] < min

        data_points.push (cap - datum[key]).to_f  # It's a visibility number, so let's inverse it to give us fog.
        datum[key] = (cap - datum[key]).to_f      # Mod the source data for the get_dot_str call below.
      end

      #differential = data_points.max - data_points.min

      str = get_dot_str(chars, data, 0, cap, key)

      "24h fog report |#{str}| visibility #{get_distance min, @scale} - #{get_distance max, @scale}"
    end

    def do_the_sunrise_thing(forecast)
      t = Time.at(fix_time(forecast['daily']['data'][0]['sunriseTime'], forecast['offset']))
      t.strftime("%H:%M:%S")
    end

    def do_the_sunset_thing(forecast)
      t = Time.at(fix_time(forecast['daily']['data'][0]['sunsetTime'], forecast['offset']))
      t.strftime("%H:%M:%S")
    end

    def conditions(forecast)
      temp_str, temps = do_the_temp_thing(forecast, 'temperature', ansi_chars, 8)
      wind_str, winds = do_the_wind_direction_thing(forecast, ansi_wind_arrows, 8)
      rain_str, rains = do_the_rain_chance_thing(forecast, ansi_chars, 'precipProbability', config.colors, 15)

      sun_chance = ((1 - forecast['daily']['data'][0]['cloudCover']) * 100).round
      "#{get_temperature temps.first.round(2)} |#{temp_str}| #{get_temperature temps.last.round(2)} "\
        "/ #{get_speed(winds.first)} |#{wind_str}| #{get_speed(winds.last)} "\
        "/ #{sun_chance}% chance of sun / 60m precip |#{rain_str}|"
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

      make_fire(max_str, maxtemps)

      differential = mintemps.max - mintemps.min
      min_str = get_dot_str(ansi_chars, data, mintemps.min, differential, 'temperatureMin')

      if config.colors
        max_str = get_colored_string(data, 'temperatureMax', max_str, get_temp_range_colors)
        min_str = get_colored_string(data, 'temperatureMin', min_str, get_temp_range_colors)
      end

      "7day high/low temps #{get_temperature maxtemps.first.to_f.round(1)} |#{max_str}| #{get_temperature maxtemps.last.to_f.round(1)} "\
        "/ #{get_temperature mintemps.first.to_f.round(1)} |#{min_str}| #{get_temperature mintemps.last.to_f.round(1)} "\
        "High range: #{get_temperature maxtemps.min} - #{get_temperature maxtemps.max}, "\
        "Low range: #{get_temperature mintemps.min} - #{get_temperature mintemps.max}"\
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

      str = get_dot_str(ansi_chars, data, 0, 1, 'precipProbability')

      if config.colors
        str = get_colored_string(data, 'precipProbability', str, get_rain_range_colors)
      end

      max = get_max_by_data_key(forecast, 'daily', 'precipProbability')
      accum = get_sum_by_data_key(forecast, 'daily', 'precipIntensity')

      "7day #{precip_type}s |#{str}| max #{max * 100}%, #{get_accumulation accum * 24} accumulation."
    end

    def do_the_daily_rain_thing(forecast, hours = 48)
      precip_type = 'rain'
      rains = []

      data = forecast['hourly']['data']
      data.each_with_index do |day, i|
        if day['precipType'] == 'snow'
          precip_type = 'snow'
        end
        rains.push day['precipProbability']
        # Lita.logger.debug("break if #{i} > #{hours}")
        break if i >= hours
      end

      # gotta send rains / not 48 h of data
      if hours < 48
        num = 48 - hours
        (0..num).each do
          data.pop
        end
      end

      str = get_dot_str(ansi_chars, data, 0, 1, 'precipProbability')

      if 'snow' == precip_type
        data.each_with_index do |datum, index|
          if datum['precipType'] == 'snow'
            str[index] = get_snowman config
          end
        end
      end

      if config.colors
        str = get_colored_string(data, 'precipProbability', str, get_rain_range_colors)
      end

      max = get_max_by_data_key(forecast, 'hourly', 'precipProbability')
      agg = get_sum_by_data_key(forecast, 'hourly', 'precipIntensity')

      "#{hours} hr #{precip_type}s |#{str}| max #{(max.to_f * 100).round}%, #{get_accumulation agg} accumulation"
    end

    def do_the_daily_wind_thing(forecast)
      winds = []

      data = forecast['daily']['data']
      data.each do |day|
        winds.push day['windSpeed']
      end

      str = get_dot_str(ansi_chars, data, 0, winds.max, 'windSpeed')

      if config.colors
        str = get_colored_string(data, 'windSpeed', str, get_wind_range_colors)
      end

      "7day winds #{get_wind_speed winds.first}|#{str}|#{get_wind_speed winds.last} range #{get_wind_speed winds.min}-#{get_wind_speed winds.max}"
    end

    def do_the_daily_humidity_thing(forecast)
      humidities = []

      data = forecast['daily']['data']
      data.each do |day|
        humidities.push day['humidity']
      end

      str = get_dot_str(ansi_chars, data, 0, 1, 'humidity')

      if config.colors
        str = get_colored_string(data, 'humidity', str, get_wind_range_colors)
      end

      "7day humidity #{get_humidity humidities.first}|#{str}|#{get_humidity humidities.last} "\
        "range #{get_humidity humidities.min}-#{get_humidity humidities.max}"
    end

    def do_the_ozone_thing(forecast)
      # O ◎ ]
      data = forecast['hourly']['data']

      str = get_dot_str(ozone_chars, data, 280, 350-280, 'ozone')

      "ozones #{data.first['ozone']} |#{str}| #{data.last['ozone']} [24h forecast]"
    end

    def do_the_pressure_thing(forecast)
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
      str = []
      forecast['alerts'].each do |alert|
        alert['description'].match /\.\.\.(\w+)\.\.\./
        desc = alert['description'][0..alert['description'].rindex('...')]
        str.push desc
        str.push alert['uri']
      end
      str
    end

    def do_the_nearest_storm_thing(forecast)
      return forecast['currently']['nearestStormDistance'], forecast['currently']['nearestStormBearing']
    end

    def do_the_today_thing(forecast, yesterday)
      Lita.logger.info "Basing today on today - yesterday: #{yesterday['daily']['data'][0]['temperatureMax']} - #{forecast['daily']['data'][0]['temperatureMax']}"
      temp_diff = yesterday['daily']['data'][0]['temperatureMax'] - forecast['daily']['data'][0]['temperatureMax']
      get_daily_comparison_text(temp_diff, forecast['daily']['data'][0]['temperatureMax'])
    end

    def do_the_tomorrow_thing(forecast)
      Lita.logger.info "Basing tomorrow on today - tomorrow: #{forecast['daily']['data'][0]['temperatureMax']} - #{forecast['daily']['data'][1]['temperatureMax']}"
      temp_diff = forecast['daily']['data'][0]['temperatureMax'] - forecast['daily']['data'][1]['temperatureMax']
      get_daily_comparison_text(temp_diff, forecast['daily']['data'][0]['temperatureMax'])
    end

    # If the temperature difference is positive,
    def get_daily_comparison_text(temp_diff, high)
      if temp_diff <= 1 and temp_diff >= -1
        'about the same as'
      elsif temp_diff > 1 and temp_diff <= 5
        'cooler than'
      elsif temp_diff > 5
        (high > 70)? 'much cooler than' : 'much colder than'
      elsif temp_diff < -1 and temp_diff >= -5
        'warmer than'
      elsif temp_diff < -5
        (high < 70)? 'much warmer than' : 'much hotter than'
      end
    end

    # Check for the time of day when it will hit 72F.
    def do_the_windows_thing(forecast, response)
      time_to_close_the_windows = nil
      time_to_open_the_windows = nil
      window_close_temp = 0
      high_temp = 0
      last_temp = 0
      output = ''

      # Insert windows setting code for detection
      #
      selected_windows = get_windows(response.user)
      Lita.logger.debug "User selected windows: #{selected_windows}"

      forecast['hourly']['data'].each_with_index do |hour, index|
        if hour['temperature'] > high_temp
          high_temp = hour['temperature'].to_i
        end

        if !time_to_close_the_windows and hour['temperature'].to_f >= 21.5
          if index.zero?
            time_to_close_the_windows = 'now'
          else
            time_to_close_the_windows = hour['time']
          end
          window_close_temp = hour['temperature']
        end

        if !time_to_open_the_windows and
           time_to_close_the_windows and
           hour['temperature'].to_f < last_temp.to_f and
           hour['temperature'].to_f <= selected_windows.to_f

          time_to_open_the_windows = hour['time']
        end

        last_temp = hour['temperature']
        break if index > 18
      end

      # Return some meta here and let the caller decide the text.
      if time_to_close_the_windows.nil?
        output = "Leave 'em open, no excess heat today(#{get_temperature high_temp})."
        if high_temp <= 18 and high_temp > 15
          output = "Open them up mid-day, high temp #{get_temperature high_temp}."
        elsif high_temp <= 18
          output = "Best leave 'em shut, high temp #{get_temperature high_temp}."
        end
      else
        # Todo: base timezone on requested location.
        timezone = TZInfo::Timezone.get('America/Los_Angeles')
        if time_to_close_the_windows == 'now'
          output = "Close the windows now! It is #{get_temperature window_close_temp}."
        else
          time_at = Time.at(time_to_close_the_windows).to_datetime
          local_time = timezone.utc_to_local(time_at)
          output = "Close the windows at #{local_time.strftime('%k:%M')}, it will be #{get_temperature window_close_temp}."
        end
        if time_to_open_the_windows
          open_time = timezone.utc_to_local(Time.at(time_to_open_the_windows).to_datetime)
          output += "  Open them back up at #{open_time.strftime('%H:%M')}."
        end
        output += "  The high today will be #{get_temperature high_temp}."
      end

      if time_to_open_the_windows.nil? and high_temp > 24    # High heat mode- it might not drop to 75 for several days in our current climate
        output += "  No suitable time to open the windows found.  I only have 48h of temperature data."
      end

      # Commenting out cuz purpleair is locking down.
      # aqi = get_aqi_data response
      # Lita.logger.debug aqi
      # stats = process_aqi_data(aqi, response)
      # Lita.logger.debug stats
      # if stats.nil?
      return output
      # end

      if stats[:v].to_i >= 75
        aqi_desc = 'moderate.'
        case stats[:v].to_i
        when 100..150
          aqi_desc = 'unhealthy.'
        when 151..200
          aqi_desc = 'don\'t go outside and like, breathe.'
        when 201..250
          aqi_desc = 'unconscionable!'
        when 251..300
          aqi_desc = 'terribad!'
        when 300..500
          aqi_desc = 'ridonculous!'
        when 500..9999
          aqi_desc = 'unbelievable.'
        end
        output = "Close the windows now!  The AQI is #{stats[:v]}, #{aqi_desc}"
      else
        output += "  Today's AQI is #{stats[:v].to_i}."
      end

      output
    end

    def do_the_windows_data_thing(forecast)
      time_to_close_the_windows = nil
      time_to_open_the_windows = nil
      window_close_temp = 0
      high_temp = 0
      last_temp = 0

      forecast['hourly']['data'].each_with_index do |hour, index|
        if hour['temperature'] > high_temp
          high_temp = hour['temperature'].to_i
        end

        if !time_to_close_the_windows and hour['temperature'].to_i >= 71
          if index.zero?
            time_to_close_the_windows = 'now'
          else
            time_to_close_the_windows = hour['time']
          end
          window_close_temp = hour['temperature']
        end

        if !time_to_open_the_windows and time_to_close_the_windows and hour['temperature'] < last_temp and hour['temperature'].to_i <= 75
          time_to_open_the_windows = hour['time']
        end

        last_temp = hour['temperature']
        break if index > 18
      end

      # Return some meta here and let the caller decide the text.
      if time_to_close_the_windows.nil?
        "Leave 'em open, no excess heat today(#{get_temperature high_temp})."
      else
        # Todo: base timezone on requested location.
        timezone = TZInfo::Timezone.get('America/Los_Angeles')
        if time_to_close_the_windows == 'now'
          output = "Close the windows now! It is #{get_temperature window_close_temp}.  "
        else
          time_at = Time.at(time_to_close_the_windows).to_datetime
          local_time = timezone.utc_to_local(time_at)
          output = "Close the windows at #{local_time.strftime('%k:%M')}, it will be #{get_temperature window_close_temp}.  "
        end
        if time_to_open_the_windows
          open_time = timezone.utc_to_local(Time.at(time_to_open_the_windows).to_datetime)
          output += "Open them back up at #{open_time.strftime('%k:%M')}.  "
        end
        output += "The high today will be #{get_temperature high_temp}."
        datas = { 'timeToClose': local_time.strftime('%k:%M'),
                  'timeToOpen': open_time.strftime('%k:%M'),
                  'tempMax': high_temp,
                  'temp': window_close_temp
        }
      end
    end

    def do_the_uvindex_thing(forecast)
      uvs = []
      forecast['hourly']['data'].each do |hour|
        uvs.push hour['uvIndex']
      end

      data = forecast['hourly']['data']
      str = get_dot_str(ansi_chars, data, uvs.min, uvs.max - uvs.min, key = 'uvIndex')

      if config.colors
        str = get_colored_string(data, 'uvIndex', str, get_uvindex_colors)
      end

      "#{uvs.first} |#{str}| #{uvs.last} max: #{uvs.max}"
    end

    def do_the_ansiwhen_thing(forecast, target, target_unit = 'F')
      Lita.logger.debug "Looking for #{target} #{target_unit}"
      target_time = nil
      temp = nil
      max = -500

      forecast['hourly']['data'].each do |hour|
        forecast_temp = fahrenheit(hour['temperature']).to_i

        if forecast_temp > max
          max = forecast_temp
        end

        if forecast_temp > target.to_i
          target_time = hour['time']
          temp = forecast_temp.to_s
          break
        end
      end

      Lita.logger.debug "Found time #{target_time} and temp #{temp} and max #{max}"
      unless target_time.nil?
        target_time = Time.at(target_time).to_datetime.strftime("%H:%M")
      end

      # target_time = DateTime.strptime(target_time.to_s, '%s')
      if target_time.nil?
        temp = max
      end

      [target_time, temp]
    end

    def do_the_aqi_thing(aqis, chars = ansi_chars)
      str = get_dot_str(chars, aqis, 0, 500, nil)
      # str = get_dot_str(chars, aqis, aqis.min, aqis.max - aqis.min, nil)

      output = "#{aqis.first} |#{str}| #{aqis.last} max: #{aqis.max}"

      if config.colors
        str = get_colored_string(aqis, nil, str, get_aqi_colors)
        output = "#{color_chars(aqis.first, get_aqi_colors)} |#{str}| #{color_chars(aqis.last, get_aqi_colors)} max: #{color_chars(aqis.max, get_aqi_colors)}"
      end

      output
    end

    def color_chars(input, range_hash)
      color = nil
      range_hash.keys.each do |range_hash_key|
        if range_hash_key.cover? input.to_i    # Super secred cover sauce
          color = range_hash[range_hash_key]
        end
      end
      colored_str = "\x03" + colors[color].to_s + input.to_s + "\x03"

    end
    private

    def get_current_apparent_temp(forecast)
      forecast['hourly']['data'][0]['apparentTemperature']
    end

    def get_aqi_data(response, api_key)
      Lita.logger.debug "get_aqi_data called with #{response.matches[0][0]}"
      sensor_id = '75007'
      # headers = {'X-API-Key':
      #            }  # Hack for the 2022 lockdown
      # ua = 'curl/7.79.1' # 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.63 Safari/537.36'

      # hardcoded map of sensors
      users = {
        # aaronpk: 43023,
        #        zenlinux: 43023,
        #        djwong: 61137,
        #        philtor: 35221,
        #        bkero: 43023,
        #        agb: 34409,
        #        donpdonp: 43023,
        #        onewheelskyward: 23805
      }
      # philomath 41507
      # corvalis 57995

      if response.matches[0][0].length > 1
        Lita.logger.debug response.matches[0][0]
        sensor_id = response.matches[0][0]
        Lita.logger.debug "Performing sensor sweep for #{sensor_id}"
        unless sensor_id
          Lita.logger.debug 'Defaulting to pdx'
          sensor_id = '9814'
        end
      end

      RestClient.log = 'stdout'
      # Lita.logger.debug("Grabbing token")
      # token = RestClient.get "https://map.purpleair.com/token",
      #                        params: {version: '1.8.52'},
      #                        headers: headers,
      #                        user_agent: ua
      # Lita.logger.debug token
      # return
      # resp = RestClient.get "https://www.purpleair.com/json",
      #                       params: {show: sensor_id},
      #                       headers: headers,
      #                       user_agent: ua

      uri_base = "https://api.purpleair.com/v1/sensors"
      uri = "#{uri_base}/#{sensor_id}?api_key=0DA903FC-0C48-11ED-8561-42010A800005"
      Lita.logger.debug "URI: #{uri}"
      resp = RestClient.get uri
                            # params: {show: sensor_id},
                            # headers: headers,
                            # user_agent: ua
      aqi = JSON.parse resp
      Lita.logger.debug aqi
      if aqi['results'].to_a.length.zero? and users.has_key? response.user.name.to_sym
        # Possible zip instead of sensor
        uri = "#{uri_base}/#{users[response.user.name.to_sym]}?api_key=#{api_key}"
        Lita.logger.debug "calling #{uri}"
        begin
          resp = RestClient.get uri
          aqi = JSON.parse resp
          Lita.logger.debug aqi
        rescue RuntimeError => e
          Lita.logger.debug "Exception found #{e}"
          return
        end
      end
      aqi
    end

    def process_aqi_data(aqi, response)
      if aqi.nil? or aqi['sensor'].to_a.empty?
        response.reply "Sensor ID #{response.matches[0][0]} not found (zip code searches are unsupported)"
        return
      end

      stats = {v: 0, v1: 0, v2: 0, v3: 0, v4: 0, v5: 0, v6: 0}
      sensor = aqi['sensor']
      stats_key = ''
      Lita.logger.debug "aqi stats: #{aqi}"
      if sensor['stats']['pm2.5'].to_f > 0
        stats_key = 'stats'
      end
      if sensor['stats_a']['pm2.5'].to_f > 0
        stats_key = 'stats_a'
      end
      if sensor['stats_b']['pm2.5'].to_f > 0
        stats_key = 'stats_b'
      end

      stats[:v] = sensor[stats_key]["pm2.5"]
      stats[:v1] = sensor[stats_key]["pm2.5_10minute"]
      stats[:v2] = sensor[stats_key]["pm2.5_30minute"]
      stats[:v3] = sensor[stats_key]["pm2.5_60minute"]
      stats[:v4] = sensor[stats_key]["pm2.5_6hour"]
      stats[:v5] = sensor[stats_key]["pm2.5_24hour"]
      stats[:v6] = sensor[stats_key]["pm2.5_1week"]

        #
      # Lita.logger.debug "Found #{aqi['results'].length} results, averaging"
      # aqi['results'].each do |r|
      #   # Lita.logger.debug r
      #   s = JSON.parse r['Stats']
      #   # Lita.logger.debug "Result: #{s}"
      #   if (s['v']).zero? or r['Flag'] == 1
      #     next
      #   end
      #   stats[:v].push s['v']
      #   stats[:v1].push s['v1']
      #   stats[:v2].push s['v2']
      #   stats[:v3].push s['v3']
      #   stats[:v4].push s['v4']
      #   stats[:v5].push s['v5']
      #   stats[:v6].push s['v6']
      # end
      #
      stats.keys.each do |statskey|
      #   avg = 0
      #   stats[statskey].each do |measurement|
      #     avg += measurement
      #   end
      #   avg = avg / stats[statskey].length
        stats[statskey] = calc_aqi stats[statskey].to_i  # Convert this to a map
      end

      Lita.logger.debug "Stats: #{stats}"
      stats
    end
  end
end
