require 'geocoder'
require 'rest_client'
require 'magic_eightball'
require_relative 'location'
require_relative 'constants'
require_relative 'irc_handlers'
require_relative 'forecasts'
require_relative 'utils'

module Lita
  module Handlers
    class OnewheelForecastIo < Handler
      config :api_key
      config :api_uri
      config :colors
      config :snowflake, default: '❄'
      config :default_location, default: 'Portland, OR'
      config :geocoder_key

      include ::ForecastIo::Constants
      include ::ForecastIo::IrcHandlers
      include ::ForecastIo::Forecasts
      include ::ForecastIo::Utils

      # Temperature routes
      route(/^ansitemp\s*$/i, :handle_irc_ansitemp, command: true)
      route(/^ansitemp\s+(.+)/i, :handle_irc_ansitemp, command: true,
            help: {'!ansitemp [location]' => 'The 24h temperature scale for [location].'})
      route(/^ansitempapparent\s*$/i, :handle_irc_ansitempapparent, command: true)
      route(/^ansitempapparent\s+(.+)/i, :handle_irc_ansitempapparent, command: true,
            help: {'!ansitemp [location]' => 'The 24h temperature scale for [location].'})
      route(/^dailytemp\s*$/i, :handle_irc_daily_temp, command: true)
      route(/^dailytemp\s+(.+)/i, :handle_irc_daily_temp, command: true,
            help: { '!dailytemp [location]' => '48h temperature scale for [location].'})
      route(/^7day\s*$/i, :handle_irc_seven_day, command: true)
      route(/^7day\s+(.+)/i, :handle_irc_seven_day, command: true,
            help: { '!7day [location]' => '7 day temperature scale, featuring highs and lows.'})
      route(/^weekly\s*$/i, :handle_irc_seven_day, command: true)
      route(/^weekly\s+(.+)/i, :handle_irc_seven_day, command: true,
            help: { '!weekly [location]' => 'Alias for !7day.'})
      route(/^asciitemp\s*$/i, :handle_irc_ascii_temp, command: true)
      route(/^asciitemp\s+(.+)/i, :handle_irc_ascii_temp, command: true,
            help: { '!asciitemp [location]' => 'Like ansitemp, but with less ansi.'})
      route(/^ieeetemp\s*$/i, :handle_irc_ieeetemp, command: true)
      route(/^ieeetemp\s+(.+)/i, :handle_irc_ieeetemp, command: true,
            help: {'!ieeetemp [location]' => 'The 24h temperature scale for [location], kelvin-style.'})

      # General forecast routes
      route(/^allrain\s*$/i, :handle_irc_all_rain, command: true)
      route(/^allrain\s+(.+)$/i, :handle_irc_all_rain, command: true)
      route(/^ansiallthethings\s*$/i, :handle_irc_all_the_things, command: true)
      route(/^forecastallthethings\s*$/i, :handle_irc_all_the_things, command: true)
      route(/^forecastallthethings\s+(.+)/i, :handle_irc_all_the_things, command: true,
            help: { '!forecastallthethings [location]' => 'A huge dump of most available info for [location].'})
      route(/^forecast\s*$/i, :handle_irc_forecast, command: true)
      route(/^forecast\s+(.+)/i, :handle_irc_forecast, command: true,
            help: { '!forecast [location]' => 'Text forcast of the location selected.'})
      route(/^weather\s*$/i, :handle_irc_forecast, command: true)
      route(/^weather\s+(.+)/i, :handle_irc_forecast, command: true,
            help: { '!weather [location]' => 'Alias for !forecast.'})
      route(/^condi*t*i*o*n*s*\s*$/i, :handle_irc_conditions, command: true)
      route(/^condi*t*i*o*n*s*\s+(.+)/i, :handle_irc_conditions, command: true,
            help: { '!cond[itions] [location]' => 'A single-line summary of the conditions at [location].'})

      # One-offs
      route(/^rain\s*$/i, :is_it_raining)
      route(/^rain\s+(.+)/i, :is_it_raining,
            help: { '!rain [location]' => 'Magic Eightball response to whether or not it is raining in [location] right now.'})
      route(/^snow\s*$/i, :is_it_snowing)
      route(/^snow\s+(.+)/i, :is_it_snowing,
            help: { '!snow [location]' => 'Magic Eightball response to whether or not it is snowing in [location] right now.'})
      route(/^geo\s*$/i, :handle_geo_lookup, command: true)
      route(/^geo\s+(.+)/i, :handle_geo_lookup, command: true,
            help: { '!geo [location]' => 'A simple geo-lookup returning GPS coords.'})
      route(/^alerts\s*$/i, :handle_irc_alerts, command: true)
      route(/^alerts\s+(.+)/i, :handle_irc_alerts, command: true,
            help: { '!alerts [location]' => 'NOAA alerts for [location].'})
      route(/^neareststorm\s*$/i, :handle_irc_neareststorm, command: true)
      route(/^neareststorm\s+(.+)$/i, :handle_irc_neareststorm, command: true,
            help: { '!neareststorm [location]' => 'Nearest storm distance for [location].'})
      route(/^tomorrow/i, :handle_irc_tomorrow, command: true,
            help: { '!tomorrow' => 'Give me tomorrow\'s forecast as it relates to today.'})
      route(/^today/i, :handle_irc_today, command: true,
            help: { '!today' => 'Give me today\'s forecast as it relates to yesterday.'})
      # route(/^Good morning./, :handle_irc_windows)  # Easter egg alert.  Thank you, zrobo and donpdonp.
      # Disabled for winter.
      route(/^linux$/i, :handle_irc_windows, command: true)
      route(/^macos$/i, :handle_irc_windows, command: true)
      route(/^osx$/i, :handle_irc_windows, command: true)
      route(/^beos$/i, :handle_irc_windows, command: true)
      route(/^os2$/i, :handle_irc_windows, command: true)
      route(/^aix$/i, :handle_irc_windows, command: true)
      route(/^unix$/i, :handle_irc_windows, command: true)
      route(/^systemv$/i, :handle_irc_windows, command: true)
      route(/^solaris$/i, :handle_irc_windows, command: true)
      route(/^sunos$/i, :handle_irc_windows, command: true)
      route(/^hpux$/i, :handle_irc_windows, command: true)
      route(/^amiga$/i, :handle_irc_windows, command: true)
      route(/^palmos$/i, :handle_irc_windows, command: true)
      route(/^ios$/i, :handle_irc_windows, command: true)
      route(/^msdos$/i, :handle_irc_windows, command: true)
      route(/^drdos$/i, :handle_irc_windows, command: true)
      route(/^freedos$/i, :handle_irc_windows, command: true)
      route(/^dos$/i, :handle_irc_windows, command: true)
      route(/^android$/i, :handle_irc_windows, command: true)
      route(/^windows$/i, :handle_irc_windows, command: true)
      route(/^windows\s+(.+)/i, :handle_irc_windows, command: true,
            help: { '!windows' => 'Tell me when to close my windows as it\'s warmer outside than in.'})

      # SUN
      route(/^uv$/i, :handle_irc_uvindex, command: true)
      route(/^uv\s+(.+)$/i, :handle_irc_uvindex, command: true)
      route(/^uvindex$/i, :handle_irc_uvindex, command: true)
      route(/^uvindex\s+(.*)$/i, :handle_irc_uvindex, command: true)
      route(/^ansiuvindex\s*(.*)$/i, :handle_irc_uvindex, command: true)
      route(/^ansiuv\s*(.*)$/i, :handle_irc_uvindex, command: true,
            help: { '!ansiuv' => 'Display the UV index forecast.' })

      # State Commands
      route(/^set scale (c|f|k)/i, :handle_irc_set_scale, command: true,
            help: { '!set scale [c|f|k]' => 'Set the scale to your chosen degrees.'})
      route(/^set scale$/i, :handle_irc_set_scale, command: true,
            help: { '!set scale' => 'Toggle between C and F scales.'})

      # Humidity
      route(/^ansihumidity\s*$/i, :handle_irc_ansi_humidity, command: true)
      route(/^ansihumidity\s+(.+)/i, :handle_irc_ansi_humidity, command: true,
            help: { '!ansihumidity [location]' => '48h humidity report for [location].'})
      route(/^dailyhumidity\s*$/i, :handle_irc_daily_humidity, command: true)
      route(/^dailyhumidity\s+(.+)/i, :handle_irc_daily_humidity, command: true,
            help: { '!dailyhumidity [location]' => '7 day humidity report.'})

      # Rain related.  Where we all started.
      route(/^ansirain\s*$/i, :handle_irc_ansirain, command: true)
      route(/^ansirain\s+(.+)/i, :handle_irc_ansirain, command: true,
            help: { '!ansirain [location]' => '60m rain chance report for [location].'})
      route(/^ansisnow\s*$/i, :handle_irc_ansirain, command: true)
      route(/^ansisnow\s+(.+)/i, :handle_irc_ansirain, command: true,
            help: { '!ansisnow [location]' => 'Alias for !ansirain.'})
      route(/^dailyrain\s*$/i, :handle_irc_daily_rain, command: true)
      route(/^dailyrain\s+(.+)/i, :handle_irc_daily_rain, command: true,
            help: { '!dailyrain [location]' => '48h rain chance report for [location].'})
      route(/^dayrain\s*$/i, :handle_irc_day_rain, command: true)
      route(/^dayrain\s+(.+)/i, :handle_irc_day_rain, command: true,
            help: { '!dayrain [location]' => '24h rain chance report for [location].'})
      route(/^dailysnow\s*$/i, :handle_irc_daily_rain, command: true)
      route(/^dailysnow\s+(.+)/i, :handle_irc_daily_rain, command: true,
            help: { '!dailysnow [location]' => 'Alias for !dailyrain.'})
      route(/^7dayrain\s*$/i, :handle_irc_seven_day_rain, command: true)
      route(/^7dayrain\s+(.+)/i, :handle_irc_seven_day_rain, command: true,
            help: { '!7dayrain [location]' => '7 day rain chance report for [location].'})
      route(/^weeklyrain\s*$/i, :handle_irc_seven_day_rain, command: true)
      route(/^weeklyrain\s+(.+)/i, :handle_irc_seven_day_rain, command: true,
            help: { '!weeklyrain [location]' => 'Alias for !7dayrain.'})
      route(/^weeklysnow\s*$/i, :handle_irc_seven_day_rain, command: true)
      route(/^weeklysnow\s+(.+)/i, :handle_irc_seven_day_rain, command: true,
            help: { '!weeklysnow [location]' => 'Alias for !7dayrain.'})
      route(/^ansiintensity\s*$/i, :handle_irc_ansirain_intensity, command: true)
      route(/^ansiintensity\s+(.+)/i, :handle_irc_ansirain_intensity, command: true,
            help: { '!ansiintensity [location]' => '60m rain intensity report for [location].'})
      route(/^asciirain\s*$/i, :handle_irc_ascii_rain, command: true)
      route(/^asciirain\s+(.+)/i, :handle_irc_ascii_rain, command: true,
            help: { '!asciirain [location]' => '60m rain chance report for [location], ascii style!'})
      route(/^asciisnow\s*$/i, :handle_irc_ascii_rain, command: true)
      route(/^asciisnow\s+(.+)/i, :handle_irc_ascii_rain, command: true,
            help: { '!asciisnow [location]' => '60m snow chance report for [location], ascii style!'})
      route(/^nextrain\s*$/i, :handle_irc_nextrain, command: true)
      route(/^nextrain\s+(.+)$/i, :handle_irc_nextrain, command: true,
            help: { '!nextrain [location]' => 'Get the next known instance of rain available.'})

      # don't start singing.
      route(/^sunrise\s*$/i, :handle_irc_sunrise, command: true)
      route(/^sunrise\s+(.+)/i, :handle_irc_sunrise, command: true,
            help: { '!sunrise [location]' => 'Get today\'s sunrise time for [location].'})
      route(/^sunset\s*$/i, :handle_irc_sunset, command: true)
      route(/^sunset\s+(.+)/i, :handle_irc_sunset, command: true,
            help: { '!sunset [location]' => 'Get today\'s sunset time for [location].'})
      route(/^ansisun\s*$/i, :handle_irc_ansisun, command: true)
      route(/^ansisun\s+(.+)/i, :handle_irc_ansisun, command: true,
            help: { '!ansisun [location]' => '48 hour chance-of-sun report for [location].'})
      route(/^dailysun\s*$/i, :handle_irc_dailysun, command: true)
      route(/^dailysun\s+(.+)/i, :handle_irc_dailysun, command: true,
            help: { '!ansisun [location]' => '7 day chance-of-sun report for [location].'})
      route(/^asciisun\s*$/i, :handle_irc_asciisun, command: true)
      route(/^asciisun\s+(.+)/i, :handle_irc_asciisun, command: true,
            help: { '!asciisun [location]' => '7 day chance-of-sun report for [location].'})

      # Mun!

      # Wind
      route(/^ansiwind\s*$/i, :handle_irc_ansiwind, command: true)
      route(/^ansiwind\s+(.+)/i, :handle_irc_ansiwind, command: true,
            help: { '!ansiwind [location]' => '24h wind speed/direction report for [location].'})
      route(/^ansiwindchill\s*$/i, :handle_irc_ansiwindchill, command: true)
      route(/^ansiwindchill\s+(.+)/i, :handle_irc_ansiwindchill, command: true,
            help: { '!ansiwindchill [location]' => '24h windchill temp report for [location].'})
      route(/^asciiwind\s*$/i, :handle_irc_ascii_wind, command: true)
      route(/^asciiwind\s+(.+)/i, :handle_irc_ascii_wind, command: true,
            help: { '!asciiwind [location]' => '24h wind speed/direction report for [location], ascii style.'})
      route(/^dailywind\s*$/i, :handle_irc_daily_wind, command: true)
      route(/^dailywind\s+(.+)/i, :handle_irc_daily_wind, command: true,
            help: { '!dailywind [location]' => '7 day wind speed/direction report for [location].'})

      # Cloud cover
      route(/^asciiclouds*\s+(.+)/i, :handle_irc_asciicloud, command: true)
      route(/^asciiclouds*\s*$/i, :handle_irc_asciicloud, command: true,
            help: { '!asciicloud [location]' => '24h cloud cover report for [location].'})
      route(/^cloudcover\s*$/i, :handle_irc_ansicloud, command: true)
      route(/^ansiclouds*\s*$/i, :handle_irc_ansicloud, command: true)
      route(/^ansiclouds*\s+(.+)/i, :handle_irc_ansicloud, command: true,
            help: { '!ansicloud [location]' => '24h cloud cover report for [location].'})
      route(/^asciifog*\s*$/i, :handle_irc_asciifog, command: true)
      route(/^asciifog*\s+(.+)/i, :handle_irc_asciifog, command: true,
            help: { '!ansicloud [location]' => '24h fog/visibility report for [location].'})
      route(/^ansifog*\s*$/i, :handle_irc_ansifog, command: true)
      route(/^ansifog*\s+(.+)/i, :handle_irc_ansifog, command: true,
            help: { '!ansicloud [location]' => '24h fog/visibility report for [location].'})

      # oooOOOoooo
      route(/^ansiozone\s*$/i, :handle_irc_ansiozone, command: true)
      route(/^ansiozone\s+(.+)/i, :handle_irc_ansiozone, command: true,
            help: { '!ansiozone [location]' => '24h ozone level report for [location].'})

      # Pressure
      route(/^ansipressure\s*$/i, :handle_irc_ansi_pressure, command: true)
      route(/^ansipressure\s+(.+)/i, :handle_irc_ansi_pressure, command: true,
            help: { '!ansipressure [location]' => '48h barometric pressure report for [location].'})
      route(/^ansibarometer\s*$/i, :handle_irc_ansi_pressure, command: true)
      route(/^ansibarometer\s+(.+)/i, :handle_irc_ansi_pressure, command: true,
            help: { '!ansibarometer [location]' => 'Alias for !ansipressure.'})
      route(/^dailypressure\s*$/i, :handle_irc_daily_pressure, command: true)
      route(/^dailypressure\s+(.+)/i, :handle_irc_daily_pressure, command: true,
            help: { '!dailypressure [location]' => '7 day barometric pressure report for [location].'})
      route(/^dailybarometer\s*$/i, :handle_irc_daily_pressure, command: true)
      route(/^dailybarometer\s+(.+)/i, :handle_irc_daily_pressure, command: true,
            help: { '!dailybarometer [location]' => 'Alias for !dailypressure.'})

      route(/^ansitraffic\s+(.+)/i, :handle_sandytraffic, command: true)
      route(/^http\s+(\d+)/i, :handle_http_cat, command: true)

      route(/^ansiaqi\s*(\d*)$/i, :handle_ansi_aqi, command: true)
      route(/^ansismoke\s*(\d*)$/i, :handle_ansi_aqi, command: true)
      route(/^emojiaqi\s*(\d*)$/i, :handle_emoji_aqi, command: true)
      route(/^aqi\s*(\d*)$/i, :handle_ansi_aqi, command: true)
      route(/^hot$/i, :handle_ansi_hot, command: true)

      route(/^ansiwhen\s+(\d{1,3})(\w*)$/, :handle_ansi_when, command: true)

      # admin
      route(/^ansiloc\s+(\w+)$/i, :handle_irc_ansiloc, command: true)

      route(/^ansitest$/i, :handle_irc_ansitest, command: true)

      http.get '/windows', :handle_http_windows
      http.post '/aqi', :handle_http_aqi
    end

    Lita.register_handler(OnewheelForecastIo)
  end
end
