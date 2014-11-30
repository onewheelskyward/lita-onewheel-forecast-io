require_relative '../../spec_helper'

describe Lita::Handlers::ForecastIo, lita_handler: true do
  # it { is_expected.to route("some message") }
  # it 'lets everyone know when someone is happy' do
  #   send_message("I'm happy!")
  #   expect(replies.last).to eq("Hey, everyone! #{user.name} is happy! Isn't that nice?")
  # end
  before(:each) do
    # allow(Lita::Handlers::ForecastIo).to receive(:geo_lookup) {
    #    Location.new('Paris, France', 45.0, :long => 44.0)
    # }
    # allow(Lita::Handlers::ForecastIo).to receive(:gimme_some_weather) { 'x' }
    registry.configure do |config|
      config.handlers.forecast_io.api_uri = 'https://api.forecast.io/forecast/'
      config.handlers.forecast_io.api_key = '5537a6b7a8e2936dc7ced091b999d60a'
    end
  end

  # Todo: mock weather data for predictable output.

  it { is_expected.to route('!rain') }
  it { is_expected.to route('!ansirain') }
  it { is_expected.to route('!ansitemp') }

  it '!ansirain no minute by minute' do
    # allow(Lita::Handlers::ForecastIo).to receive(:get_forecast_io_results) { "x" }
    # res = Lita::Handlers::ForecastIo::get_forecast_io_results('Paris')
    send_message '!ansirain Paris'
    expect(replies.last).to include 'No minute-by-minute data available.'
  end

  it '!ansirain portland' do
    # allow(Lita::Handlers::ForecastIo).to receive(:get_forecast_io_results) { "x" }
    # res = Lita::Handlers::ForecastIo::get_forecast_io_results('Paris')
    send_message '!ansirain portland'
    expect(replies.last).to include 'rain probability'
  end

  it '!ansitemp portland' do
    send_message '!ansitemp portland'
    expect(replies.last).to include('temps: now')
  end
end
