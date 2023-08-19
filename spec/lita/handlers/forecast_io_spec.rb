# frozen_string_literal: true

require_relative '../../spec_helper'
require 'geocoder'
require 'webmock/rspec'
require 'timecop'
require 'rest_client'

# include WebMock::API

def mock_up(filename)
  mock_weather_json = File.open("spec/fixtures/#{filename}.json").read
  stub_request(:get, /api.forecast.io\/forecast\//)
    .to_return(status: 200, body: mock_weather_json, headers: {})
  # allow(RestClient).to receive(:get) { mock_weather_json }
end

describe Lita::Handlers::OnewheelForecastIo, lita_handler: true do
  before(:each) do
    Geocoder.configure(lookup: :test)

    stub_request(:get, /atlas.p3k.io\/api\/geocode\?input\=Portland/i)
      .to_return(status: 200, body: '{"latitude":45.480620000000044,"longitude":-122.61289,"locality":"Portland","region":"Oregon","country":"USA","best_name":"Portland","full_name":"Portland, Oregon, USA","postal-code":"97206","timezone":"America\/Los_Angeles","offset":"-07:00","seconds":-25200,"localtime":"2021-09-30T15:38:19-07:00"}', headers: {})
    stub_request(:get, /atlas.p3k.io\/api\/geocode\?input\=Paris/)
      .to_return(status: 200, body: '{"latitude":48.856614,"longitude":2.3522219,"locality":"Paris","region":"France","country":"France","best_name":"Paris","full_name":"Paris, France","timezone":"Europe\/CEST","offset":"+01:00","seconds":3600,"localtime":"2021-09-30T15:38:19-07:00"}', headers: {})

    stub_request(:get, 'https://www.purpleair.com/json?show=23805')
      .to_return(status: 200, body: '{"mapVersion":"0.30","baseVersion":"7","mapVersionString":"","results":[{"ID":23805,"Label":"South Tabor ","DEVICE_LOCATIONTYPE":"outside","THINGSPEAK_PRIMARY_ID":"664034","THINGSPEAK_PRIMARY_ID_READ_KEY":"0F01UC3P6VHUM2DL","THINGSPEAK_SECONDARY_ID":"664035","THINGSPEAK_SECONDARY_ID_READ_KEY":"57M497H7034S7WLN","Lat":45.504625,"Lon":-122.595016,"PM2_5Value":"0.0","LastSeen":1633418752,"Type":"PMS5003+PMS5003+BME280","Hidden":"false","DEVICE_BRIGHTNESS":"15","DEVICE_HARDWAREDISCOVERED":"2.0+BME280+PMSX003-B+PMSX003-A","Version":"6.01","LastUpdateCheck":1633416710,"Created":1545958052,"Uptime":"3259120","RSSI":"-80","Adc":"0.0","p_0_3_um":"0.0","p_0_5_um":"0.0","p_1_0_um":"0.0","p_2_5_um":"0.0","p_5_0_um":"0.0","p_10_0_um":"0.0","pm1_0_cf_1":"0.0","pm2_5_cf_1":"0.0","pm10_0_cf_1":"0.0","pm1_0_atm":"0.0","pm2_5_atm":"0.0","pm10_0_atm":"0.0","isOwner":0,"humidity":"62","temp_f":"66","pressure":"1003.28","AGE":0,"Stats":"{\"v\":0.0,\"v1\":0.0,\"v2\":0.0,\"v3\":0.0,\"v4\":0.0,\"v5\":0.0,\"v6\":0.0,\"pm\":0.0,\"lastModified\":1633418752750,\"timeSinceModified\":119983}"},{"ID":23806,"ParentID":23805,"Label":"South Tabor  B","THINGSPEAK_PRIMARY_ID":"664036","THINGSPEAK_PRIMARY_ID_READ_KEY":"0GE4D5OHVVZMI94N","THINGSPEAK_SECONDARY_ID":"664037","THINGSPEAK_SECONDARY_ID_READ_KEY":"3PCV6F3THPCXW3GE","Lat":45.504625,"Lon":-122.595016,"PM2_5Value":"40.92","LastSeen":1633418752,"Hidden":"false","Created":1545958052,"Adc":"0.00","p_0_3_um":"5715.62","p_0_5_um":"1700.06","p_1_0_um":"296.83","p_2_5_um":"25.09","p_5_0_um":"6.04","p_10_0_um":"0.26","pm1_0_cf_1":"31.28","pm2_5_cf_1":"50.0","pm10_0_cf_1":"53.89","pm1_0_atm":"26.09","pm2_5_atm":"40.92","pm10_0_atm":"50.15","isOwner":0,"AGE":0,"Stats":"{\"v\":40.92,\"v1\":40.81,\"v2\":40.74,\"v3\":39.74,\"v4\":23.77,\"v5\":13.75,\"v6\":7.62,\"pm\":40.92,\"lastModified\":1633418752750,\"timeSinceModified\":119983}"}]}', headers: {})

    # Mock up the ForecastAPI call.
    # Todo: add some other mocks to allow more edgy testing (rain percentages, !rain eightball replies, etc
    mock_up('mock_weather')

    registry.configure do |config|
      config.handlers.onewheel_forecast_io.api_uri = 'https://api.forecast.io/forecast'
      config.handlers.onewheel_forecast_io.api_key = ''
      config.handlers.onewheel_forecast_io.colors = true
    end
  end

  it '!forecast' do
    send_command 'forecast'
    expect(replies.last).to eq('Portland, Oregon, USA weather is currently 83.1°F and clear.  Winds out of the E at 5.74 kph. It will be clear for the hour, and flurries tomorrow morning.  There are also 357.71 ozones.')
  end

  # it '!rain' do
  #   allow(MagicEightball).to receive(:reply) { 'Nope' }
  #   send_message 'rain Portland'
  #   expect(replies.last).to eq('Nope')
  # end

  # it '!snow' do
  #   allow(MagicEightball).to receive(:reply) { 'Nope' }
  #   send_message 'snow Portland'
  #   expect(replies.last).to eq('Nope')
  # end

  it '!ansirain Paris' do
    send_command 'ansirain Paris'
    expect(replies.last).to include("|\u000302_❄\u000306▃\u000310▅\u000303▅\u000309▅\u000311▇\u000308▇\u000307█\u000304█\u000313█\u000302__________________________________________________\u0003|")
  end

  it '!ansirain return max chance' do
    send_command 'ansirain Paris'
    expect(replies.last).to include('max 100.0%')
  end

  it '!ansirain no minutes' do
    mock_up 'mock_weather_no_minute'
    send_command 'ansirain'
    expect(replies.last).to include('|No minute-by-minute data available.|')
  end

  it '!ansiintensity no minutes' do
    mock_up 'mock_weather_no_minute'
    send_command 'ansiintensity'
    expect(replies.last).to include('|No minute-by-minute data available.|')
  end

  it '!ansisnow Paris' do
    send_command 'ansisnow Paris'
    expect(replies.last).to include("|\u000302_❄\u000306▃\u000310▅\u000303▅\u000309▅\u000311▇\u000308▇\u000307█\u000304█\u000313█\u000302__________________________________________________\u0003|")
  end

  it '!ansiintensity' do
    send_command 'ansiintensity'
    expect(replies.last).to include('Portland, Oregon, USA 1hr snow intensity')
  end

  it '!ansitemp portland' do
    send_command 'ansitemp portland'
    expect(replies.last).to eq("Portland, Oregon, USA 24 hr temps: 82.94°F (feels like 74.23°F) |\u000307_▁\u000304▃▅▇\u000305█\u000313███\u000305█\u000304▇▅▅▅▃▃▃▃\u000307▃▁▃▁▁\u0003| 83.12°F  Range: 82.94°F - 100.58°F")
  end

  it '!ieeetemp portland' do
    send_command 'ieeetemp portland'
    expect(replies.last).to eq("Portland, Oregon, USA 24 hr temps: 487.97K (feels like 483.13K) |\u000307_▁\u000304▃▅▇\u000305█\u000313███\u000305█\u000304▇▅▅▅▃▃▃▃\u000307▃▁▃▁▁\u0003| 488.07K  Range: 487.97K - 497.77K")
  end

  it '!dailytemp portland' do
    send_command 'dailytemp portland'
    expect(replies.last).to eq("Portland, Oregon, USA 48 hr temps: 82.94°F (feels like 74.23°F) |07_▁04▃▅▅05▇13██▇05▇04▅▅▅▃▃▃▃▃07▁▁▁▁▁▁▁04▃▅▅05▇13🔥🔥🔥🔥🔥▇05▇▇▇04▅▅▅▅▅▃▃▃▃| 86.9°F  Range: 82.94°F - 106.34°F")
  end

  it '!ansiwind portland' do
    send_command 'ansiwind portland'
    expect(replies.last).to eq("Portland, Oregon, USA 48h wind direction 14.4 kph|\u000306↓\u000310↙←\u000311↖↑↗\u000308→↘\u000311↓←←←←←←\u000310←←←←←←←\u000306←←←←←\u000302←←←↙↙↙↙↓↓↓\u000306↓↓↓↓↓↓↓↓↙↙\u0003|14.4 kph Range: 3.6 kph - 43.2 kph, gusting to 0.0 kph")
  end

  it '!conditions' do
    send_command 'conditions'
    expect(replies.last).to eq("Portland, Oregon, USA 82.94°F |\u000307_▁\u000304▃▅▇\u000305█\u000313█\u0003| 100.58°F / 4.3 kph |\u000306↓\u000310↙←\u000311↖↑↗\u000308→\u0003| 12.71 kph / 98% chance of sun / 60m precip |\u000306❄\u000311▇\u000308▇\u000302_____________\u0003|")
  end

  it '!alerts' do
    send_command 'alerts'
    expect(replies.last).to eq('http://alerts.weather.gov/cap/wwacapget.php?x=OR125178E7B298.SpecialWeatherStatement.12517D218640OR.PQRSPSPQR.53656f1fdba795381a7895d7e3d153f7')
  end

  it '!ansisun' do
    send_command 'ansisun'
    expect(replies.last).to eq("Portland, Oregon, USA 48hr sun forecast |\u000308████████████████████\u000307▇▇▅\u000309▅▅▃\u000303▁_▁\u000309▃▃▃\u000303▁▁▁▁▃\u000309▃▅\u000307▇▇▇▇\u000308▇▇▇▇▇▇\u0003| max 100%")
  end

  it '!dailysun' do
    send_command 'dailysun'
    expect(replies.last).to eq("Portland, Oregon, USA 8 day sun forecast |\u000308█\u000309▃\u000308▇\u000309▁_\u000307▅\u000309▃\u000307▅\u0003| max 76%")
  end

  it '!asciisun' do
    send_command 'asciisun'
    expect(replies.last).to eq("Portland, Oregon, USA 48hr sun forecast |\u000308''''''''''''''''''''\u000307**~\u000309~~-\u000303._.\u000309---\u000303....-\u000309-~\u000307****\u000308******\u0003| max 100%")
  end

  it '!ansicloud' do
    send_command 'ansicloud'
    expect(replies.last).to eq('Portland, Oregon, USA 24h cloud cover |___________▁▁▁▁▁▁▁▁▃▅▅▅| range 0% - 49.0%')
  end

  it '!asciicloud' do
    send_command 'asciicloud'
    expect(replies.last).to eq('Portland, Oregon, USA 24h cloud cover |___________........-~~~| range 0% - 49.0%')
  end

  it '!asciitemp' do
    send_command 'asciitemp'
    expect(replies.last).to eq("Portland, Oregon, USA 24 hr temps: 82.94°F (feels like 74.23°F) |07_.04-~*05'13'''05'04*~~~----07-.-..| 83.12°F  Range: 82.94°F - 100.58°F")
  end

  it '!asciirain' do
    send_command 'asciirain'
    expect(replies.last).to include("|\u000302_❄\u000306-\u000310~\u000303~\u000309~\u000311*\u000308*\u000307'\u000304'\u000313'\u000302__________________________________________________\u0003|")
  end

  it '!7day' do
    send_command '7day'
    expect(replies.last).to eq("Portland, Oregon, USA 7day high/low temps 102.2°F |13🔥🔥🔥🔥🔥🔥🔥🔥| 126.32°F / 82.76°F |07_▁04▃▅13█05▇13██| 103.46°F Range: 82.71°F - 126.28°F")
  end

  it '!dailyrain' do
    send_command 'dailyrain'
    expect(replies.last).to eq("Portland, Oregon, USA 48 hr snows |\u000302_______________________❄❄❄❄▁▁▁▁▁▁▁▁▁▁▁▁▁❄❄❄❄❄❄❄❄_\u0003| max 4%, 0mm accumulation")
  end

  it '!7dayrain' do
    send_command '7dayrain'
    expect(replies.last).to eq("Portland, Oregon, USA 7day snows |\u000302_▁▁\u000306▃\u000313█\u000303▅▅\u000310▃\u0003| max 100%, 1mm accumulation.")
  end

  it '!ansiozone' do
    send_command 'ansiozone'
    expect(replies.last).to eq('Portland, Oregon, USA ozones 357.98 |??????????◉◉◉??????????◉◉◉◉◉◉◉◉◉◉◉◉◉◉◉◉◉◎◎◎◎◎◎◎◎◎| 330.44 [24h forecast]')
  end

  it '!set scale f' do
    send_command 'set scale f'
    expect(replies.last).to eq('Scale set to f')
  end

  it '!set scale k' do
    send_command 'set scale k'
    expect(replies.last).to eq('Scale set to k')
  end

  it '!set scale already set' do
    send_command 'set scale f'
    send_command 'set scale f'
    expect(replies.last).to eq('Scale is already set to f!')
  end

  it '!set scale c' do
    send_command 'set scale c'
    expect(replies.last).to eq('Scale set to c')
  end

  it '!set scale toggle' do
    send_command 'set scale f'
    expect(replies.last).to eq('Scale set to f')
    send_command 'set scale'
    expect(replies.last).to eq('Scale set to c')
    send_command 'set scale'
    expect(replies.last).to eq('Scale set to f')
  end

  it '!ansitemp in F' do
    send_command 'set scale f'
    send_command 'ansitemp'
    expect(replies.last).to eq("Portland, Oregon, USA 24 hr temps: 82.94°F (feels like 74.23°F) |07_▁04▃▅▇05█13███05█04▇▅▅▅▃▃▃▃07▃▁▃▁▁| 83.12°F  Range: 82.94°F - 100.58°F")
  end

  it '!ansitemp in k' do
    send_command 'set scale k'
    send_command 'ansitemp'
    expect(replies.last).to eq("Portland, Oregon, USA 24 hr temps: 487.97K (feels like 483.13K) |07_▁04▃▅▇05█13███05█04▇▅▅▅▃▃▃▃07▃▁▃▁▁| 488.07K  Range: 487.97K - 497.77K")
  end

  it '!ansitemp in K' do
    send_command 'set scale K'
    send_command 'ansitemp'
    expect(replies.last).to eq("Portland, Oregon, USA 24 hr temps: 487.97K (feels like 483.13K) |07_▁04▃▅▇05█13███05█04▇▅▅▅▃▃▃▃07▃▁▃▁▁| 488.07K  Range: 487.97K - 497.77K")
  end

  it '!ansitemp in C' do
    send_command 'set scale c'
    send_command 'ansitemp'
    expect(replies.last).to eq("Portland, Oregon, USA 24 hr temps: 28.3°C (feels like 23.46°C) |07_▁04▃▅▇05█13███05█04▇▅▅▅▃▃▃▃07▃▁▃▁▁| 28.4°C  Range: 28.3°C - 38.1°C")
  end

  it '!ansiwind in MPH' do
    send_command 'set scale f'
    send_command 'ansiwind'
    expect(replies.last).to include('Portland, Oregon, USA 48h wind direction 9.0 mph')
  end

  it '!ansiwind in KPH' do
    send_command 'set scale c'
    send_command 'ansiwind'
    expect(replies.last).to include('Portland, Oregon, USA 48h wind direction 14.4 kph')
  end

  it '!sunrise' do
    send_command 'sunrise'
    expect(replies.last).to include('Portland, Oregon, USA sunrise: ')
  end

  it '!sunset' do
    send_command 'sunset'
    expect(replies.last).to include('Portland, Oregon, USA sunset: ')
  end

  it '!dailywind' do
    send_command 'dailywind'
    expect(replies.last).to include("Portland, Oregon, USA 7day winds 25.2 kph|\u000310█\u000306▅\u000310██\u000302▅▅▅")
  end

  it '!ansihumidity' do
    send_command 'ansihumidity'
    expect(replies.last).to eq("Portland, Oregon, USA 48hr humidity 67%|\u000307▇\u000308▇▇▇\u000311▅▅▅▅▅▅▅▅▅▅\u000308▇▇▇▇▇▇▇\u000307▇▇▇▇▇▇▇▇▇▇▇▇\u000304████████████████\u0003|80% range: 41%-85%")
  end

  it '!dailyhumidity' do
    send_command 'dailyhumidity'
    expect(replies.last).to eq("Portland, Oregon, USA 7day humidity 58%|\u000302▇▇▇▇████\u0003|87% range 58%-93%")
  end

  it '!forecastallthethings' do
    send_command 'forecastallthethings'
    expect(replies[0]).to eq('Portland, Oregon, USA weather is currently 83.1°F and clear.  Winds out of the E at 5.74 kph. It will be clear for the hour, and flurries tomorrow morning.  There are also 357.71 ozones.')
    expect(replies[1]).to include("|\u000302_❄\u000306▃\u000310▅\u000303▅\u000309▅\u000311▇\u000308▇\u000307█\u000304█\u000313█\u000302__________________________________________________\u0003|")
    expect(replies[2]).to include('Portland, Oregon, USA 1hr snow intensity')
    expect(replies[3]).to eq("Portland, Oregon, USA 24 hr temps: 82.94°F (feels like 74.23°F) |07_▁04▃▅▇05█13███05█04▇▅▅▅▃▃▃▃07▃▁▃▁▁| 83.12°F  Range: 82.94°F - 100.58°F")
    expect(replies[4]).to include('Portland, Oregon, USA 48h wind direction 14.4 kph')
    expect(replies[5]).to eq("Portland, Oregon, USA 48hr sun forecast |\u000308████████████████████\u000307▇▇▅\u000309▅▅▃\u000303▁_▁\u000309▃▃▃\u000303▁▁▁▁▃\u000309▃▅\u000307▇▇▇▇\u000308▇▇▇▇▇▇\u0003| max 100%")
    expect(replies[6]).to eq('Portland, Oregon, USA 24h cloud cover |___________▁▁▁▁▁▁▁▁▃▅▅▅| range 0% - 49.0%')
    expect(replies[7]).to eq("Portland, Oregon, USA 48 hr snows |\u000302_______________________❄❄❄❄▁▁▁▁▁▁▁▁▁▁▁▁▁❄❄❄❄❄❄❄❄_\u0003| max 4%, 0mm accumulation")
    expect(replies.last).to eq("Portland, Oregon, USA 67%|\u000307▇\u000308▇▇▇\u000311▅▅▅▅▅▅▅▅▅▅\u000308▇▇▇▇▇▇▇\u000307▇▇▇▇▇▇▇▇▇▇▇▇\u000304████████████████\u0003|80% range: 41%-85%")
  end

  it '!ansipressure' do
    send_command 'ansipressure'
    expect(replies.last).to eq('Portland, Oregon, USA pressure 1021.2 hPa |████▇▅▅▃▃▃▃▅▇▇▇▇▇▅▅▅▅▅▃▃▃▃▅▅▅▃▁▁▁__▁▁▃▃▅▅▅▅▅▃▁▁▁▃| 1018.31 hPa range: 1017.96-1021.2 hPa [48h forecast]')
  end

  it '!ansibarometer' do
    send_command 'ansibarometer'
    expect(replies.last).to eq('Portland, Oregon, USA pressure 1021.2 hPa |████▇▅▅▃▃▃▃▅▇▇▇▇▇▅▅▅▅▅▃▃▃▃▅▅▅▃▁▁▁__▁▁▃▃▅▅▅▅▅▃▁▁▁▃| 1018.31 hPa range: 1017.96-1021.2 hPa [48h forecast]')
  end

  it '!dailypressure' do
    send_command 'dailypressure'
    expect(replies.last).to eq('Portland, Oregon, USA pressure 1019.92 hPa |▅▅▃_▁▇██| 1027.26 hPa range: 1013.45-1027.26 hPa [8 day forecast]')
  end

  it '!dailybarometer' do
    send_command 'dailybarometer'
    expect(replies.last).to eq('Portland, Oregon, USA pressure 1019.92 hPa |▅▅▃_▁▇██| 1027.26 hPa range: 1013.45-1027.26 hPa [8 day forecast]')
  end

  it '!asciiwind' do
    send_command 'asciiwind'
    expect(replies.last).to include('Portland, Oregon, USA 48h wind direction 4.3 kph')
  end

  it '!geo' do
    send_command 'geo Paris, france'
    expect(replies.last).to eq('48.856614, 2.3522219')
  end

  it '!neareststorm' do
    send_command 'neareststorm'
    expect(replies.last).to eq('The nearest storm is 98.75 mi to the S of you.')
  end

  it '!neareststorm is zero' do
    mock_up 'heavy_rain'

    send_command 'neareststorm'
    expect(replies.last).to eq('You\'re in it!')
  end

  it '!neareststorm with scale' do
    send_command 'set scale c'
    send_command 'neareststorm'
    expect(replies.last).to eq('The nearest storm is 158 km to the S of you.')
  end

  it '!tomorrows' do
    send_command 'tomorrow'
    expect(replies.last).to eq('Tomorrow will be warmer than today.')
  end

  it '!tomorrows' do
    mock_up 'much_warmer'
    send_command 'tomorrow'
    expect(replies.last).to eq('Tomorrow will be much warmer than today.')
  end

  it '!windows' do
    mock_up 'windows'
    send_command 'windows'
    expect(replies.last).to eq('Close the windows now!  The AQI is 112, unhealthy.')
  end

  it '!windows in c' do
    mock_up 'windows'
    send_command 'set scale c'
    send_command 'windows'
    expect(replies.last).to eq('Close the windows now!  The AQI is 112, unhealthy.')
  end

  it 'will not say a 28.000000000000004% chance of rain' do
    mock_up '28000000000004percent'
    send_command 'dailyrain'
    expect(replies.last).to eq("Portland, Oregon, USA 48 hr rains |\u000302▁_▁\u000306▃▃▃\u000310▅\u000302▁_▁▁\u000306▃\u000302▁\u000310▃\u000306▃\u000310▅\u000306▃\u000302▁▁▁▁▁▁__________________________\u0003| max 28%, 0mm accumulation")
  end

  # it 'will return windows for good morning' do
  #   mock_up 'windows'
  #   send_message 'Good morning.'
  #   expect(replies.last).to eq('Close the windows at 16:00, it will be 72°F.  Open them back up at 17:00.  The high today will be 72°F.')
  # end
  #
  # it 'will return windows for good morning' do
  #   mock_up 'windows'
  #   send_message 'good morning!'
  #   expect(replies.last).to eq(nil)
  # end
  #
  it 'will summarize !today in relation to yesterday' do
    send_command 'today'
    expect(replies.last).to eq('Today will be about the same as yesterday.')
  end

  # it 'colors strings' do
  # cstr = Lita::Handlers::ForecastIo.get_colored_string([{:key => 1}], :key, 'x', {1 => :blue})
  # expect(cstr).to equal('x')
  # end

  it '!ansifog' do
    mock_up 'ansifog'
    send_command 'ansifog'
    expect(replies.last).to eq('Portland, Oregon, USA 24h fog report |▅▅▃____________________| visibility 9.12 km - 16 km')
  end

  # it '!windows 0200s' do
  #   mock_up '0200-windows'
  #   send_command 'windows'
  #   expect(replies.last).to eq('Close the windows now! It is 90.59°F.  Open them back up at 02:00.  The high today will be 96.8°F.')
  # end

  # it 'aqis' do
  #   mock_up 'aqi'
  #   send_command 'ansiaqi'
  #   expect(replies.last).to eq("AQI report for PSU STAR LAB SEL: PM2.5 \u00030866\u0003 |\u000308_\u000304▅\u000306▇\u000314████\u0003| \u000314368\u0003 max: \u000314368\u0003 \u000314(7 day average to 10 min average)\u0003")
  # end

  it '!7day extreme' do
    mock_up '7dayextreme'
    send_command '7day'
    expect(replies.last).to eq("Portland, Oregon, USA 7day high/low temps 87.08°F |\u000304_▃\u000313🔥🔥🔥\u000305▇▅\u000304▅\u0003| 93.92°F / 56.12°F |\u000311_▅\u000308▇\u000307██\u000308▇▇▇\u0003| 67.46°F Range: 56.16°F - 108.41°F")
  end

  it '!ansitemp extremes' do
    mock_up '7dayextreme'
    send_command 'ansitemp'
    expect(replies.last).to eq("Portland, Oregon, USA 24 hr temps: 86.36°F (feels like 86.27°F) |\u000304▇\u000313🔥🔥\u000307▅▅▅\u000308▅▃▃▃▁▁\u000311_\u000308▁▁▃▃\u000307▅▅▅▅\u000304▇▇\u0003| 88.52°F  Range: 64.76°F - 102.2°F")
  end

  it '!ansiwhen 80s' do
    mock_up '7dayextreme'
    send_command 'ansiwhen 80F'
    expect(replies.last).to include('It will be 86F at')
    expect(replies.last).to include('in Portland, Oregon, USA')
  end

  it '!ansitempapparents' do
    send_command 'ansitempapparent portland'
    expect(replies.last).to eq("Portland, Oregon, USA 24 hr apparent temps: 74.3°F |08▃_▃07▅▇▇04███07█▇▅08▃▁▃▃▃▃▁▁▃▁▁| 72.14°F  Range: 70.52°F - 88.7°F")
  end

  # todo: replace with actual wind-chilly day
  it '!ansiwindchills' do
    send_command 'ansiwindchill portland'
    expect(replies.last).to eq("Portland, Oregon, USA 24 hr windchill temps: 86.9°F |07??04?▃▅05▇13▇▇▇05▇04▅▃▁▁▁???07?????| 87.26°F  Range: 86.9°F - 108.32°F")
  end

  it '!ansifogs' do
    send_command 'ansifog portland'
    expect(replies.last).to eq("Portland, Oregon, USA 24h fog report |▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅| visibility 10 km - 10 km")
  end

  it '!allrains' do
    send_command 'allrain portland'
    expect(replies[0]).to include("Portland, Oregon, USA 1hr snow probability")
    expect(replies[0]).to include("|02_❄06▃10▅03▅09▅11▇08▇07█04█13█02__________________________________________________|")
    expect(replies[1]).to include("Portland, Oregon, USA 1hr snow intensity")
    expect(replies[1]).to include("|02_13▁10▁03▁09▁11▁08▁07▁04▁13▁02___________________________________________________|")
    expect(replies[2]).to include("Portland, Oregon, USA 48 hr snows |02_______________________❄❄❄❄▁▁▁▁▁▁▁▁▁▁▁▁▁❄❄❄❄❄❄❄❄_| max 4%, 0mm accumulation")
  end

  it '!nextrains' do
    new_time = Time.utc(2021, 11, 8, 18, 0, 0)
    Timecop.freeze(new_time)
    mock_up 'raininbound'
    send_command 'nextrain'
    expect(replies.last).to eq('In Portland, Oregon, USA the next rain is forecast in about 13 hours')
    Timecop.return
  end

  it '!dayrains' do
    mock_up 'raininbound'
    send_command 'dayrain'
    expect(replies.last).to eq 'Portland, Oregon, USA 24 hr rains |02▁▁▁_▁▁03▅04███07█11▇03▅▅▅10▅▃▃▃06▃10▅▅03▅▅| max 89%, 10mm accumulation'
  end

  it '!nextrains in minutes' do
    new_time = Time.at(1636422000)
    Timecop.freeze(new_time)
    mock_up 'raininminutes'
    send_command 'nextrain'
    expect(replies.last).to eq 'In Portland, Oregon, USA the next rain is forecast in 6 minutes, ending in about 12 minutes.  Max intensity is low.'
  end

  it '!nextrain nows' do
    new_time = Time.at(1637006300)
    Timecop.freeze(new_time)
    mock_up 'rainnow'
    send_command 'nextrain'
    expect(replies.last).to eq 'In Portland, Oregon, USA the next rain is forecast for now, ending in a long while.  Max intensity is hide ya pets hide ya kids.'
  end

  it '!nextrain nows til tomorrow' do
    new_time = Time.at(1637352000)
    Timecop.freeze(new_time)
    mock_up 'rainendingtomorrow'
    send_command 'nextrain'
    expect(replies.last).to eq 'In Portland, Oregon, USA the next rain is forecast for now, ending in a long while.  Max intensity is hide ya pets hide ya kids.'
  end

  it '!nextrain looks far off in the future' do
    new_time = Time.at(1643411056)
    Timecop.freeze(new_time)
    mock_up 'blindmelon'
    send_command 'nextrain'
    expect(replies.last).to eq 'In Portland, Oregon, USA the next rain is forecast for now, ending in a long while.  Max intensity is hide ya pets hide ya kids.'
  end

  it 'tests weatherkit object' do
    require './lib/lita/handlers/weatherkit.rb'
    wk = Weatherkit.new('')
    token = wk.jwt_it_down('')
    puts "Token: #{token}"

    resp = RestClient.get "https://weatherkit.apple.com/api/v1/availability/37.323/122.032?country=US",
                          headers: {'Authorization': "Bearer: #{token}"}
    puts resp
    # params: {show: sensor_id},
    # headers: headers,
    # user_agent: ua

  end
end
