module ForecastIo
  module ImgHandlers
    # get rmagicky with it
    def handle_img_rain(response)
      location = geo_lookup(response.user, response.match_data[1])
      forecast = get_forecast_io_results(response.user, location)
      response.reply img_to_url(img_rain_forecast(forecast, location))
    end

    def handle_img_duckyou(response)
      response.reply img_to_url(duck_you(response.matches[0][0]))
    end
  end
end
