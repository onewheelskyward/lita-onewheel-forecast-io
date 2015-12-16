module ForecastIo
  module Forecasts
    def ascii_rain_forecast(forecast)
      str = do_the_rain_chance_thing(forecast, ascii_chars, 'precipProbability')
      max = get_max_by_data_key(forecast, 'minutely', 'precipProbability')
      "1hr rain probability #{(Time.now).strftime('%H:%M').to_s}|#{str}|#{(Time.now + 3600).strftime('%H:%M').to_s} max #{max * 100}%"
    end

    def ansi_rain_forecast(forecast)
      str = do_the_rain_chance_thing(forecast, ansi_chars, 'precipProbability') #, 'probability', get_rain_range_colors)
      max = get_max_by_data_key(forecast, 'minutely', 'precipProbability')
      "1hr rain probability #{(Time.now).strftime('%H:%M').to_s}|#{str}|#{(Time.now + 3600).strftime('%H:%M').to_s} max #{max.to_f * 100}%"
    end

    def ansi_rain_intensity_forecast(forecast)
      str = do_the_rain_intensity_thing(forecast, ansi_chars, 'precipIntensity') #, 'probability', get_rain_range_colors)
      max_str = get_max_by_data_key(forecast, 'minutely', 'precipIntensity')
      "1hr rain intensity #{(Time.now).strftime('%H:%M').to_s}|#{str}|#{(Time.now + 3600).strftime('%H:%M').to_s} #{max_str}"
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

    def get_min_by_data_key(forecast, key, datum)
      unless forecast[key].nil?
        data_points = []
        forecast[key]['data'].each do |data_point|
          data_points.push data_point[datum]
        end
        data_points.min
      end
    end

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
            str[index] = '☃'
          end
        end
      end

      if use_color
        str = get_colored_string(data, key, str, get_rain_range_colors)
      end

      str
    end

    def do_the_rain_intensity_thing(forecast, chars, key) #, type, range_colors = nil)
      if forecast['minutely'].nil?
        return 'No minute-by-minute data available.'  # The "Middle of Nowhere" case.
      end

      data_points = []
      data = forecast['minutely']['data']

      data.each do |datum|
        data_points.push datum[key]
      end

      # Fixed range graph- 0-0.11.
      str = get_dot_str(chars, data, 0, 0.11, key)

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

    def ascii_temp_forecast(forecast, hours = 24)
      str, temperature_data = do_the_temp_thing(forecast, ascii_chars, hours)
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
    end

    def ansi_wind_direction_forecast(forecast)
      str, data = do_the_wind_direction_thing(forecast, ansi_wind_arrows)
      "48h wind direction #{get_speed data.first}|#{str}|#{get_speed data.last} Range: #{get_speed(data.min)} - #{get_speed(data.max)}"
    end

    def ascii_wind_direction_forecast(forecast)
      str, data = do_the_wind_direction_thing(forecast, ascii_wind_arrows)
      "48h wind direction #{get_speed data.first}|#{str}|#{get_speed data.last} Range: #{get_speed(data.min)} - #{get_speed(data.max)}"
    end

    def do_the_wind_direction_thing(forecast, wind_arrows, hours = 48)
      key = 'windBearing'
      data = forecast['hourly']['data'].slice(0,hours - 1)
      str = ''
      data_points = []

      data.each_with_index do |datum, index|
        wind_arrow_index = get_cardinal_direction_from_bearing(datum[key])
        str << wind_arrows[wind_arrow_index].to_s
        data_points.push datum['windSpeed']
        break if index == hours - 1 # We only want (hours) of data.
      end

      if config.colors
        str = get_colored_string(data, 'windSpeed', str, get_wind_range_colors)
      end

      return str, data_points
    end

    def do_the_sun_thing(forecast, chars)
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

      max = 1 - get_min_by_data_key(forecast, 'hourly', key)

      "8 day sun forecast |#{str}| max #{max * 100}%"
    end

    def do_the_cloud_thing(forecast, chars)
      # O ◎ ]
      data = forecast['hourly']['data'].slice(0,23)

      max = 0
      data.each do |datum|
        if datum['cloudCover'] > max
          max = datum['cloudCover']
        end
      end
      str = get_dot_str(chars, data, 0, 1, 'cloudCover')

      "24h cloud cover |#{str}| max #{max * 100}%"
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
      temp_str, temps = do_the_temp_thing(forecast, ansi_chars, 8)
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

      differential = mintemps.max - mintemps.min
      min_str = get_dot_str(ansi_chars, data, mintemps.min, differential, 'temperatureMin')

      if config.colors
        max_str = get_colored_string(data, 'temperatureMax', max_str, get_temp_range_colors)
        min_str = get_colored_string(data, 'temperatureMin', min_str, get_temp_range_colors)
      end

      "7day high/low temps #{get_temperature maxtemps.first.to_f.round(1)} |#{max_str}| #{get_temperature maxtemps.last.to_f.round(1)} "\
        "/ #{get_temperature mintemps.first.to_f.round(1)} |#{min_str}| #{get_temperature mintemps.last.to_f.round(1)} "\
        "Range: #{get_temperature mintemps.min} - #{get_temperature maxtemps.max}"
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

      "7day #{precip_type}s |#{str}| max #{max * 100}%"
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

      str = get_dot_str(ansi_chars, data, 0, 1, 'precipProbability')

      if config.colors
        str = get_colored_string(data, 'precipProbability', str, get_rain_range_colors)
      end

      max = get_max_by_data_key(forecast, 'hourly', 'precipProbability')

      "48 hr #{precip_type}s |#{str}| max #{max.to_f * 100}%"
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

      "7day winds #{get_speed winds.first}|#{str}|#{get_speed winds.last} range #{get_speed winds.min}-#{get_speed winds.max}"
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
      str = ''
      forecast['alerts'].each do |alert|
        alert['description'].match /\.\.\.(\w+)\.\.\./
        str += "#{alert['uri']}\n"
      end
      str
    end

    def do_the_nearest_storm_thing(forecast)
      return forecast['currently']['nearestStormDistance'], forecast['currently']['nearestStormBearing']
    end
  end
end
