module ForecastIo
  module ImgHandlers
    # get rmagicky with it
    def handle_img_rain(response)
      location = geo_lookup(response.user, response.match_data[1])
      forecast = get_forecast_io_results(response.user, location)
      response.reply img_rain_forecast(forecast)
    end
  end
end
