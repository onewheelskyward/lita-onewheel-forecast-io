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

      include ::ForecastIo::Constants
      include ::ForecastIo::IrcHandlers
      include ::ForecastIo::Forecasts
      include ::ForecastIo::Utils

      # Temperature routes
      route(/^ansitemp\s*$/i, :handle_irc_ansitemp)
      route(/^ansitemp\s+(.+)/i, :handle_irc_ansitemp,
            help: {'!ansitemp [location]' => 'The 24h temperature scale for [location].'})
      route(/^dailytemp\s*$/i, :handle_irc_daily_temp)
      route(/^dailytemp\s+(.+)/i, :handle_irc_daily_temp,
            help: { '!dailytemp [location]' => '48h temperature scale for [location].'})
      route(/^7day\s*$/i, :handle_irc_seven_day)
      route(/^7day\s+(.+)/i, :handle_irc_seven_day,
            help: { '!7day [location]' => '7 day temperature scale, featuring highs and lows.'})
      route(/^weekly\s*$/i, :handle_irc_seven_day)
      route(/^weekly\s+(.+)/i, :handle_irc_seven_day,
            help: { '!weekly [location]' => 'Alias for !7day.'})
      route(/^asciitemp\s*$/i, :handle_irc_ascii_temp)
      route(/^asciitemp\s+(.+)/i, :handle_irc_ascii_temp,
            help: { '!asciitemp [location]' => 'Like ansitemp, but with less ansi.'})

      # General forecast routes
      route(/^forecastallthethings\s*$/i, :handle_irc_all_the_things)
      route(/^forecastallthethings\s+(.+)/i, :handle_irc_all_the_things,
            help: { '!forecastallthethings [location]' => 'A huge dump of most available info for [location].'})
      route(/^forecast\s*$/i, :handle_irc_forecast)
      route(/^forecast\s+(.+)/i, :handle_irc_forecast,
            help: { '!forecast [location]' => 'Text forcast of the location selected.'})
      route(/^weather\s*$/i, :handle_irc_forecast)
      route(/^weather\s+(.+)/i, :handle_irc_forecast,
            help: { '!weather [location]' => 'Alias for !forecast.'})
      route(/^condi*t*i*o*n*s*\s*$/i, :handle_irc_conditions)
      route(/^condi*t*i*o*n*s*\s+(.+)/i, :handle_irc_conditions,
            help: { '!cond[itions] [location]' => 'A single-line summary of the conditions at [location].'})

      # One-offs
      route(/^rain\s*$/i, :is_it_raining)
      route(/^rain\s+(.+)/i, :is_it_raining,
            help: { '!rain [location]' => 'Magic Eightball response to whether or not it is raining in [location] right now.'})
      route(/^snow\s*$/i, :is_it_snowing)
      route(/^snow\s+(.+)/i, :is_it_snowing,
            help: { '!snow [location]' => 'Magic Eightball response to whether or not it is snowing in [location] right now.'})
      route(/^geo\s*$/i, :handle_geo_lookup)
      route(/^geo\s+(.+)/i, :handle_geo_lookup,
            help: { '!geo [location]' => 'A simple geo-lookup returning GPS coords.'})
      route(/^alerts\s*$/i, :handle_irc_alerts)
      route(/^alerts\s+(.+)/i, :handle_irc_alerts,
            help: { '!alerts [location]' => 'NOAA alerts for [location].'})
      route(/^neareststorm\s*$/i, :handle_irc_neareststorm)
      route(/^neareststorm\s+(.+)$/i, :handle_irc_neareststorm,
            help: { '!neareststorm [location]' => 'Nearest storm distance for [location].'})

      # State Commands
      route(/^set scale (c|f|k)/i, :handle_irc_set_scale,
            help: { '!set scale [c|f|k]' => 'Set the scale to your chosen degrees.'})
      route(/^set scale$/i, :handle_irc_set_scale,
            help: { '!set scale' => 'Toggle between C and F scales.'})

      # Humidity
      route(/^ansihumidity\s*$/i, :handle_irc_ansi_humidity)
      route(/^ansihumidity\s+(.+)/i, :handle_irc_ansi_humidity,
            help: { '!ansihumidity [location]' => '48h humidity report for [location].'})
      route(/^dailyhumidity\s*$/i, :handle_irc_daily_humidity)
      route(/^dailyhumidity\s+(.+)/i, :handle_irc_daily_humidity,
            help: { '!dailyhumidity [location]' => '7 day humidity report.'})

      # Rain related.  Where we all started.
      route(/^ansirain\s*$/i, :handle_irc_ansirain)
      route(/^ansirain\s+(.+)/i, :handle_irc_ansirain,
            help: { '!ansirain [location]' => '60m rain chance report for [location].'})
      route(/^ansisnow\s*$/i, :handle_irc_ansirain)
      route(/^ansisnow\s+(.+)/i, :handle_irc_ansirain,
            help: { '!ansisnow [location]' => 'Alias for !ansirain.'})
      route(/^dailyrain\s*$/i, :handle_irc_daily_rain)
      route(/^dailyrain\s+(.+)/i, :handle_irc_daily_rain,
            help: { '!dailyrain [location]' => '48h rain chance report for [location].'})
      route(/^dailysnow\s*$/i, :handle_irc_daily_rain)
      route(/^dailysnow\s+(.+)/i, :handle_irc_daily_rain,
            help: { '!dailysnow [location]' => 'Alias for !dailyrain.'})
      route(/^7dayrain\s*$/i, :handle_irc_seven_day_rain)
      route(/^7dayrain\s+(.+)/i, :handle_irc_seven_day_rain,
            help: { '!7dayrain [location]' => '7 day rain chance report for [location].'})
      route(/^weeklyrain\s*$/i, :handle_irc_seven_day_rain)
      route(/^weeklyrain\s+(.+)/i, :handle_irc_seven_day_rain,
            help: { '!weeklyrain [location]' => 'Alias for !7dayrain.'})
      route(/^weeklysnow\s*$/i, :handle_irc_seven_day_rain)
      route(/^weeklysnow\s+(.+)/i, :handle_irc_seven_day_rain,
            help: { '!weeklysnow [location]' => 'Alias for !7dayrain.'})
      route(/^ansiintensity\s*$/i, :handle_irc_ansirain_intensity)
      route(/^ansiintensity\s+(.+)/i, :handle_irc_ansirain_intensity,
            help: { '!ansiintensity [location]' => '60m rain intensity report for [location].'})
      route(/^asciirain\s*$/i, :handle_irc_ascii_rain)
      route(/^asciirain\s+(.+)/i, :handle_irc_ascii_rain,
            help: { '!asciirain [location]' => '60m rain chance report for [location], ascii style!'})

      # don't start singing.
      route(/^sunrise\s*$/i, :handle_irc_sunrise)
      route(/^sunrise\s+(.+)/i, :handle_irc_sunrise,
            help: { '!sunrise [location]' => 'Get today\'s sunrise time for [location].'})
      route(/^sunset\s*$/i, :handle_irc_sunset)
      route(/^sunset\s+(.+)/i, :handle_irc_sunset,
            help: { '!sunset [location]' => 'Get today\'s sunset time for [location].'})
      route(/^ansisun\s*$/i, :handle_irc_ansisun)
      route(/^ansisun\s+(.+)/i, :handle_irc_ansisun,
            help: { '!ansisun [location]' => '7 day chance-of-sun report for [location].'})
      route(/^asciisun\s*$/i, :handle_irc_asciisun)
      route(/^asciisun\s+(.+)/i, :handle_irc_asciisun,
            help: { '!asciisun [location]' => '7 day chance-of-sun report for [location].'})

      # Mun!

      # Wind
      route(/^ansiwind\s*$/i, :handle_irc_ansiwind)
      route(/^ansiwind\s+(.+)/i, :handle_irc_ansiwind,
            help: { '!ansiwind [location]' => '24h wind speed/direction report for [location].'})
      route(/^asciiwind\s*$/i, :handle_irc_ascii_wind)
      route(/^asciiwind\s+(.+)/i, :handle_irc_ascii_wind,
            help: { '!asciiwind [location]' => '24h wind speed/direction report for [location], ascii style.'})
      route(/^dailywind\s*$/i, :handle_irc_daily_wind)
      route(/^dailywind\s+(.+)/i, :handle_irc_daily_wind,
            help: { '!dailywind [location]' => '7 day wind speed/direction report for [location].'})

      # Cloud cover
      route(/^asciiclouds*\s+(.+)/i, :handle_irc_asciicloud)
      route(/^asciiclouds*\s*$/i, :handle_irc_asciicloud,
            help: { '!asciicloud [location]' => '24h cloud cover report for [location].'})
      route(/^ansiclouds*\s*$/i, :handle_irc_ansicloud)
      route(/^ansiclouds*\s+(.+)/i, :handle_irc_ansicloud,
            help: { '!ansicloud [location]' => '24h cloud cover report for [location].'})

      # oooOOOoooo
      route(/^ansiozone\s*$/i, :handle_irc_ansiozone)
      route(/^ansiozone\s+(.+)/i, :handle_irc_ansiozone,
            help: { '!ansiozone [location]' => '24h ozone level report for [location].'})

      # Pressure
      route(/^ansipressure\s*$/i, :handle_irc_ansi_pressure)
      route(/^ansipressure\s+(.+)/i, :handle_irc_ansi_pressure,
            help: { '!ansipressure [location]' => '48h barometric pressure report for [location].'})
      route(/^ansibarometer\s*$/i, :handle_irc_ansi_pressure)
      route(/^ansibarometer\s+(.+)/i, :handle_irc_ansi_pressure,
            help: { '!ansibarometer [location]' => 'Alias for !ansipressure.'})
      route(/^dailypressure\s*$/i, :handle_irc_daily_pressure)
      route(/^dailypressure\s+(.+)/i, :handle_irc_daily_pressure,
            help: { '!dailypressure [location]' => '7 day barometric pressure report for [location].'})
      route(/^dailybarometer\s*$/i, :handle_irc_daily_pressure)
      route(/^dailybarometer\s+(.+)/i, :handle_irc_daily_pressure,
            help: { '!dailybarometer [location]' => 'Alias for !dailypressure.'})

    end

    Lita.register_handler(OnewheelForecastIo)
  end
end
