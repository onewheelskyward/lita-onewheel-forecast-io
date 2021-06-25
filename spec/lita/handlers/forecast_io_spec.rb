require_relative '../../spec_helper'
require 'geocoder'

def mock_up(filename)
  mock_weather_json = File.open("spec/fixtures/#{filename}.json").read
  allow(RestClient).to receive(:get) { mock_weather_json }
end

describe Lita::Handlers::OnewheelForecastIo, lita_handler: true do
  before(:each) do
    Geocoder.configure(:lookup => :test)

    Geocoder::Lookup::Test.add_stub(
      'Portland, OR', [
        {
          'formatted_address' => 'Portland, OR, USA',

          'geometry' => {
            'location' => {
              'lat' => 45.523452,
              'lng' => -122.676207,
              'address' => 'Portland, OR, USA',
              'state' => 'Oregon',
              'state_code' => 'OR',
              'country' => 'United States',
              'country_code' => 'US'
            }
          }
        }
      ]
    )

    Geocoder::Lookup::Test.add_stub(
      'Portland', [
        {
          'formatted_address' => 'Portland, OR, USA',
          'geometry' => {
            'location' => {
              'lat' => 45.523452,
              'lng' => -122.676207,
              'address' => 'Portland, OR, USA',
              'state' => 'Oregon',
              'state_code' => 'OR',
              'country' => 'United States',
              'country_code' => 'US'
            }
          }
        }
      ]
    )

    Geocoder::Lookup::Test.add_stub(
      'portland', [
        {
          'formatted_address' => 'Portland, OR, USA',
          'geometry' => {
            'location' => {
              'lat' => 45.523452,
              'lng' => -122.676207,
              'address' => 'Portland, OR, USA',
              'state' => 'Oregon',
              'state_code' => 'OR',
              'country' => 'United States',
              'country_code' => 'US'
            }
          }
        }
      ]
    )

    Geocoder::Lookup::Test.add_stub(
      'Paris, france', [
        {
          'formatted_address' => 'Paris, FR',
          'geometry' => {
            'location' => {
              'lat' => 48.856614,
              'lng' => 2.3522219,
              'address' => 'Paris, FR',
              'state' => 'm',
              'state_code' => 'm',
              'country' => 'France',
              'country_code' => 'FR'
            }
          }
        }
      ]
    )

    Geocoder::Lookup::Test.add_stub(
      'Paris', [
        {
          'formatted_address' => 'Paris, FR',
          'geometry' => {
            'location' => {
              'lat' => 48.856614,
              'lng' => 2.3522219,
              'address' => 'Paris, FR',
              'state' => 'm',
              'state_code' => 'm',
              'country' => 'France',
              'country_code' => 'FR'
            }
          }
        }
      ]
    )

    # Mock up the ForecastAPI call.
    # Todo: add some other mocks to allow more edgy testing (rain percentages, !rain eightball replies, etc
    mock_up('mock_weather')

    registry.configure do |config|
      config.handlers.onewheel_forecast_io.api_uri = ''
      config.handlers.onewheel_forecast_io.api_key = ''
      config.handlers.onewheel_forecast_io.colors = true
    end
  end

  it { is_expected.to route_command('forecast') }
  it { is_expected.to route_command('weather') }
  it { is_expected.to route('rain') }
  it { is_expected.to route('snow') }
  it { is_expected.to route_command('ansirain') }
  it { is_expected.to route_command('ansisnow') }
  it { is_expected.to route_command('ansihumidity') }
  it { is_expected.to route_command('ansiintensity') }
  it { is_expected.to route_command('ansitemp') }
  it { is_expected.to route_command('ieeetemp') }
  it { is_expected.to route_command('ansiwind') }
  it { is_expected.to route_command('asciiwind') }
  it { is_expected.to route_command('ansisun') }
  it { is_expected.to route_command('dailysun') }
  it { is_expected.to route_command('asciisun') }
  it { is_expected.to route_command('asciicloud') }
  it { is_expected.to route_command('ansicloud') }
  it { is_expected.to route_command('ansiclouds') }
  it { is_expected.to route_command('asciitemp') }
  it { is_expected.to route_command('asciirain') }
  it { is_expected.to route_command('7day') }
  it { is_expected.to route_command('weekly') }
  it { is_expected.to route_command('dailyrain') }
  it { is_expected.to route_command('dailysnow') }
  it { is_expected.to route_command('dailytemp') }
  it { is_expected.to route_command('dailyhumidity') }
  it { is_expected.to route_command('7dayrain') }
  it { is_expected.to route_command('weeklyrain') }
  it { is_expected.to route_command('weeklysnow') }
  it { is_expected.to route_command('dailywind') }
  it { is_expected.to route_command('alerts') }
  it { is_expected.to route_command('ansiozone') }
  it { is_expected.to route_command('cond') }
  it { is_expected.to route_command('condi') }
  it { is_expected.to route_command('condit') }
  it { is_expected.to route_command('conditi') }
  it { is_expected.to route_command('conditio') }
  it { is_expected.to route_command('condition') }
  it { is_expected.to route_command('conditions') }
  it { is_expected.to route_command('set scale f') }
  it { is_expected.to route_command('set scale c') }
  it { is_expected.to route_command('set scale k') }
  it { is_expected.to route_command('set scale') }
  it { is_expected.to route_command('sunrise') }
  it { is_expected.to route_command('sunset') }
  it { is_expected.to route_command('forecastallthethings') }
  it { is_expected.to route_command('ansipressure') }
  it { is_expected.to route_command('ansibarometer') }
  it { is_expected.to route_command('dailypressure') }
  it { is_expected.to route_command('dailybarometer') }
  it { is_expected.to route_command('neareststorm') }
  it { is_expected.to route_command('tomorrow') }
  it { is_expected.to route_command('windows') }

  # This is where we test for regex overflow, so !weeklyrain doesn't try to get a forecast for Rain, Germany.
  it { is_expected.not_to route_command('forecastrain') }
  it { is_expected.not_to route_command('weatherrain') }
  it { is_expected.not_to route_command('rainrain') }
  it { is_expected.not_to route_command('snowrain') }
  it { is_expected.not_to route_command('ansirainrain') }
  it { is_expected.not_to route_command('ansisnowrain') }
  it { is_expected.not_to route_command('ansihumidityrain') }
  it { is_expected.not_to route_command('ansiintensityrain') }
  it { is_expected.not_to route_command('ansitemprain') }
  it { is_expected.not_to route_command('ansiwindrain') }
  it { is_expected.not_to route_command('asciiwindrain') }
  it { is_expected.not_to route_command('ansisunrain') }
  it { is_expected.not_to route_command('ansicloudrain') }
  it { is_expected.not_to route_command('asciitemprain') }
  it { is_expected.not_to route_command('asciirainrain') }
  it { is_expected.not_to route_command('dailyrainrain') }
  it { is_expected.not_to route_command('dailysnowrain') }
  it { is_expected.not_to route_command('dailytemprain') }
  it { is_expected.not_to route_command('dailyhumidityrain') }
  it { is_expected.not_to route_command('7dayrainrain') }
  it { is_expected.not_to route_command('weeklyrainrain') }
  it { is_expected.not_to route_command('weeklysnowrain') }
  it { is_expected.not_to route_command('dailywindrain') }
  it { is_expected.not_to route_command('alertsrain') }
  it { is_expected.not_to route_command('ansiozonerain') }
  it { is_expected.not_to route_command('condrain') }
  it { is_expected.not_to route_command('condirain') }
  it { is_expected.not_to route_command('conditrain') }
  it { is_expected.not_to route_command('conditirain') }
  it { is_expected.not_to route_command('conditiorain') }
  it { is_expected.not_to route_command('conditionrain') }
  it { is_expected.not_to route_command('conditionsrain') }
  it { is_expected.not_to route_command('sunriserain') }
  it { is_expected.not_to route_command('sunsetrain') }
  it { is_expected.not_to route_command('forecastallthethingsrain') }
  it { is_expected.not_to route_command('ansipressurerain') }
  it { is_expected.not_to route_command('ansibarometerrain') }
  it { is_expected.not_to route_command('dailypressurerain') }
  it { is_expected.not_to route_command('dailybarometerrain') }

  it '!forecast' do
    send_command 'forecast'
    expect(replies.last).to eq("Portland, OR, USA weather is currently 83.1°F and clear.  Winds out of the E at 5.74 kph. It will be clear for the hour, and flurries tomorrow morning.  There are also 357.71 ozones.")
  end

  it '!rain' do
    allow(MagicEightball).to receive(:reply) { 'Nope' }
    send_message 'rain Portland'
    expect(replies.last).to eq('Nope')
  end

  it '!snow' do
    allow(MagicEightball).to receive(:reply) { 'Nope' }
    send_message 'snow Portland'
    expect(replies.last).to eq('Nope')
  end

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
    expect(replies.last).to include("Portland, OR, USA 1hr snow intensity")
  end

  it '!ansitemp portland' do
    send_command 'ansitemp portland'
      expect(replies.last).to eq("Portland, OR, USA 24 hr temps: 82.94°F (feels like 74.23°F) |\u000307_▁\u000304▃▅▇\u000305█\u000313███\u000305█\u000304▇▅▅▅▃▃▃▃\u000307▃▁▃▁▁\u0003| 83.12°F  Range: 82.94°F - 100.58°F")
  end

  it '!ieeetemp portland' do
    send_command 'ieeetemp portland'
    expect(replies.last).to eq("Portland, OR, USA 24 hr temps: 487.97K (feels like 483.13K) |\u000307_▁\u000304▃▅▇\u000305█\u000313███\u000305█\u000304▇▅▅▅▃▃▃▃\u000307▃▁▃▁▁\u0003| 488.07K  Range: 487.97K - 497.77K")
  end

  it '!dailytemp portland' do
    send_command 'dailytemp portland'
    expect(replies.last).to eq("Portland, OR, USA 48 hr temps: 82.94°F (feels like 74.23°F) |07_▁04▃▅▅05▇13██▇05▇04▅▅▅▃▃▃▃▃07▁▁▁▁▁▁▁04▃▅▅05▇13█████▇05▇▇▇04▅▅▅▅▅▃▃▃▃| 86.9°F  Range: 82.94°F - 106.34°F")
  end

  it '!ansiwind portland' do
    send_command 'ansiwind portland'
    expect(replies.last).to eq("Portland, OR, USA 48h wind direction 14.4 kph|06↓10↙←11↖↑↗08→↘11↓←←←←←←10←←←←←←←06←←←←←02←←←↙↙↙↙↓↓↓06↓↓↓↓↓↓↓↓↙↙|14.4 kph Range: 3.6 kph - 43.2 kph, gusting to 0.0 kph")
  end

  it '!conditions' do
    send_command 'conditions'
    expect(replies.last).to eq("Portland, OR, USA 82.94°F |07_▁04▃▅▇05█13█| 101.7°F / 4.3 kph |06↓10↙←11↖↑↗08→| 12.71 kph / 98% chance of sun / 60m precip |06❄11▇08▇02_____________|")
  end

  it '!alerts' do
    send_command 'alerts'
    expect(replies.last).to eq("http://alerts.weather.gov/cap/wwacapget.php?x=OR125178E7B298.SpecialWeatherStatement.12517D218640OR.PQRSPSPQR.53656f1fdba795381a7895d7e3d153f7")
  end

  it '!ansisun' do
    send_command 'ansisun'
    expect(replies.last).to eq("Portland, OR, USA 48hr sun forecast |\u000308████████████████████\u000307▇▇▅\u000309▅▅▃\u000303▁_▁\u000309▃▃▃\u000303▁▁▁▁▃\u000309▃▅\u000307▇▇▇▇\u000308▇▇▇▇▇▇\u0003| max 100%")
  end

  it '!dailysun' do
    send_command 'dailysun'
    expect(replies.last).to eq("Portland, OR, USA 8 day sun forecast |\u000308█\u000309▃\u000308▇\u000309▁_\u000307▅\u000309▃\u000307▅\u0003| max 76%")
  end

  it '!asciisun' do
    send_command 'asciisun'
    expect(replies.last).to eq("Portland, OR, USA 48hr sun forecast |\u000308''''''''''''''''''''\u000307**~\u000309~~-\u000303._.\u000309---\u000303....-\u000309-~\u000307****\u000308******\u0003| max 100%")
  end

  it '!ansicloud' do
    send_command 'ansicloud'
    expect(replies.last).to eq('Portland, OR, USA 24h cloud cover |___________▁▁▁▁▁▁▁▁▃▅▅▅| range 0% - 49.0%')
  end

  it '!asciicloud' do
    send_command 'asciicloud'
    expect(replies.last).to eq('Portland, OR, USA 24h cloud cover |___________........-~~~| range 0% - 49.0%')
  end

  it '!asciitemp' do
    send_command 'asciitemp'
    expect(replies.last).to eq("Portland, OR, USA 24 hr temps: 82.94°F (feels like 74.23°F) |07_.04-~*05'13'''05'04*~~-----07-....| 83.12°F  Range: 82.94°F - 102.2°F")
  end

  it '!asciirain' do
    send_command 'asciirain'
    expect(replies.last).to include("|\u000302_❄\u000306-\u000310~\u000303~\u000309~\u000311*\u000308*\u000307'\u000304'\u000313'\u000302__________________________________________________\u0003|")
  end

  it '!7day' do
    send_command '7day'
    expect(replies.last).to eq("Portland, OR, USA 7day high/low temps 102.2°F |\u000313_▃▅▅▅███\u0003| 126.32°F / 82.76°F |\u000307_▁\u000304▃▅\u000313█\u000305▇\u000313██\u0003| 103.46°F Range: 82.71°F - 126.28°F")
  end

  it '!dailyrain' do
    send_command 'dailyrain'
    expect(replies.last).to eq("Portland, OR, USA 48 hr snows |\u000302_______________________❄❄❄❄▁▁▁▁▁▁▁▁▁▁▁▁▁❄❄❄❄❄❄❄❄_\u0003| max 4%, 0mm accumulation")
  end

  it '!7dayrain' do
    send_command '7dayrain'
    expect(replies.last).to eq("Portland, OR, USA 7day snows |\u000302_▁▁\u000306▃\u000313█\u000303▅▅\u000310▃\u0003| max 100%, 1mm accumulation.")
  end

  it '!ansiozone' do
    send_command 'ansiozone'
    expect(replies.last).to eq("Portland, OR, USA ozones 357.98 |??????????◉◉◉??????????◉◉◉◉◉◉◉◉◉◉◉◉◉◉◉◉◉◎◎◎◎◎◎◎◎◎| 330.44 [24h forecast]")
  end

  it '!set scale f' do
    send_command 'set scale f'
    expect(replies.last).to eq("Scale set to f")
  end

  it '!set scale k' do
    send_command 'set scale k'
    expect(replies.last).to eq("Scale set to k")
  end

  it '!set scale already set' do
    send_command 'set scale f'
    send_command 'set scale f'
    expect(replies.last).to eq("Scale is already set to f!")
  end

  it '!set scale c' do
    send_command 'set scale c'
    expect(replies.last).to eq("Scale set to c")
  end

  it '!set scale toggle' do
    send_command 'set scale f'
    expect(replies.last).to eq("Scale set to f")
    send_command 'set scale'
    expect(replies.last).to eq("Scale set to c")
    send_command 'set scale'
    expect(replies.last).to eq("Scale set to f")
  end

  it '!ansitemp in F' do
    send_command 'set scale f'
    send_command 'ansitemp'
    expect(replies.last).to eq("Portland, OR, USA 24 hr temps: 82.94°F (feels like 74.23°F) |\u000307_▁\u000304▃▅▇\u000305█\u000313███\u000305█\u000304▇▅▅▃▃▃▃▃\u000307▃▁▁▁▁\u0003| 83.12°F  Range: 82.94°F - 102.2°F")
  end

  it '!ansitemp in k' do
    send_command 'set scale k'
    send_command 'ansitemp'
    expect(replies.last).to eq("Portland, OR, USA 24 hr temps: 487.97K (feels like 483.13K) |\u000307_▁\u000304▃▅▇\u000305█\u000313███\u000305█\u000304▇▅▅▃▃▃▃▃\u000307▃▁▁▁▁\u0003| 488.07K  Range: 487.97K - 498.67K")
  end

  it '!ansitemp in K' do
    send_command 'set scale K'
    send_command 'ansitemp'
    expect(replies.last).to eq("Portland, OR, USA 24 hr temps: 487.97K (feels like 483.13K) |\u000307_▁\u000304▃▅▇\u000305█\u000313███\u000305█\u000304▇▅▅▃▃▃▃▃\u000307▃▁▁▁▁\u0003| 488.07K  Range: 487.97K - 498.67K")
  end

  it '!ansitemp in C' do
    send_command 'set scale c'
    send_command 'ansitemp'
    expect(replies.last).to eq("Portland, OR, USA 24 hr temps: 28.3°C (feels like 23.46°C) |\u000307_▁\u000304▃▅▇\u000305█\u000313███\u000305█\u000304▇▅▅▃▃▃▃▃\u000307▃▁▁▁▁\u0003| 28.4°C  Range: 28.3°C - 39.0°C")
  end

  it '!ansiwind in MPH' do
    send_command 'set scale f'
    send_command 'ansiwind'
    expect(replies.last).to include("Portland, OR, USA 48h wind direction 9.0 mph")
  end

  it '!ansiwind in KPH' do
    send_command 'set scale c'
    send_command 'ansiwind'
    expect(replies.last).to include("Portland, OR, USA 48h wind direction 14.4 kph")
  end

  it '!sunrise' do
    send_command 'sunrise'
    expect(replies.last).to include("Portland, OR, USA sunrise: ")
  end

  it '!sunset' do
    send_command 'sunset'
    expect(replies.last).to include("Portland, OR, USA sunset: ")
  end

  it '!dailywind' do
    send_command 'dailywind'
    expect(replies.last).to include("Portland, OR, USA 7day winds 25.2 kph|\u000310█\u000306▅\u000310██\u000302▅▅▅")
  end

  it '!ansihumidity' do
    send_command 'ansihumidity'
    expect(replies.last).to eq("Portland, OR, USA 48hr humidity 67%|\u000307▇\u000308▇▇▇\u000311▅▅▅▅▅▅▅▅▅▅\u000308▇▇▇▇▇▇▇\u000307▇▇▇▇▇▇▇▇▇▇▇▇\u000304████████████████\u0003|80% range: 41%-85%")
  end

  it '!dailyhumidity' do
    send_command 'dailyhumidity'
    expect(replies.last).to eq("Portland, OR, USA 7day humidity 58%|\u000302▇▇▇▇████\u0003|87% range 58%-93%")
  end

  it '!forecastallthethings' do
    send_command 'forecastallthethings'
    expect(replies[0]).to eq("Portland, OR, USA weather is currently 83.1°F and clear.  Winds out of the E at 5.74 kph. It will be clear for the hour, and flurries tomorrow morning.  There are also 357.71 ozones.")
    expect(replies[1]).to include("|\u000302_❄\u000306▃\u000310▅\u000303▅\u000309▅\u000311▇\u000308▇\u000307█\u000304█\u000313█\u000302__________________________________________________\u0003|")
    expect(replies[2]).to include("Portland, OR, USA 1hr snow intensity")
    expect(replies[3]).to eq("Portland, OR, USA 24 hr temps: 82.94°F (feels like 74.23°F) |\u000307_▁\u000304▃▅▇\u000305█\u000313███\u000305█\u000304▇▅▅▃▃▃▃▃\u000307▃▁▁▁▁\u0003| 83.12°F  Range: 82.94°F - 102.2°F")
    expect(replies[4]).to include("Portland, OR, USA 48h wind direction 14.4 kph")
    expect(replies[5]).to eq("Portland, OR, USA 48hr sun forecast |\u000308████████████████████\u000307▇▇▅\u000309▅▅▃\u000303▁_▁\u000309▃▃▃\u000303▁▁▁▁▃\u000309▃▅\u000307▇▇▇▇\u000308▇▇▇▇▇▇\u0003| max 100%")
    expect(replies[6]).to eq("Portland, OR, USA 24h cloud cover |___________▁▁▁▁▁▁▁▁▃▅▅▅| range 0% - 49.0%")
    expect(replies[7]).to eq("Portland, OR, USA 48 hr snows |\u000302_______________________❄❄❄❄▁▁▁▁▁▁▁▁▁▁▁▁▁❄❄❄❄❄❄❄❄_\u0003| max 4%, 0mm accumulation")
    expect(replies.last).to eq("Portland, OR, USA 67%|\u000307▇\u000308▇▇▇\u000311▅▅▅▅▅▅▅▅▅▅\u000308▇▇▇▇▇▇▇\u000307▇▇▇▇▇▇▇▇▇▇▇▇\u000304████████████████\u0003|80% range: 41%-85%")
  end

  it '!ansipressure' do
    send_command 'ansipressure'
    expect(replies.last).to eq("Portland, OR, USA pressure 1021.2 hPa |████▇▅▅▃▃▃▃▅▇▇▇▇▇▅▅▅▅▅▃▃▃▃▅▅▅▃▁▁▁__▁▁▃▃▅▅▅▅▅▃▁▁▁▃| 1018.31 hPa range: 1017.96-1021.2 hPa [48h forecast]")
  end

  it '!ansibarometer' do
    send_command 'ansibarometer'
    expect(replies.last).to eq("Portland, OR, USA pressure 1021.2 hPa |████▇▅▅▃▃▃▃▅▇▇▇▇▇▅▅▅▅▅▃▃▃▃▅▅▅▃▁▁▁__▁▁▃▃▅▅▅▅▅▃▁▁▁▃| 1018.31 hPa range: 1017.96-1021.2 hPa [48h forecast]")
  end

  it '!dailypressure' do
    send_command 'dailypressure'
    expect(replies.last).to eq("Portland, OR, USA pressure 1019.92 hPa |▅▅▃_▁▇██| 1027.26 hPa range: 1013.45-1027.26 hPa [8 day forecast]")
  end

  it '!dailybarometer' do
    send_command 'dailybarometer'
    expect(replies.last).to eq("Portland, OR, USA pressure 1019.92 hPa |▅▅▃_▁▇██| 1027.26 hPa range: 1013.45-1027.26 hPa [8 day forecast]")
  end

  it '!asciiwind' do
    send_command 'asciiwind'
    expect(replies.last).to include("Portland, OR, USA 48h wind direction 4.3 kph")
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
    expect(replies.last).to eq('Close the windows now! It is 82.94°F.  The high today will be 161.6°F.')
  end

  it '!windows in c' do
    mock_up 'windows'
    send_command 'set scale c'
    send_command 'windows'
    expect(replies.last).to eq('Close the windows now! It is 28.3°C.  The high today will be 72°C.')
  end

  it 'will not say a 28.000000000000004% chance of rain' do
    mock_up '28000000000004percent'
    send_command 'dailyrain'
    expect(replies.last).to eq("Portland, OR, USA 48 hr rains |02▁_▁06▃▃▃10▅02▁_▁▁06▃02▁10▃06▃10▅06▃02▁▁▁▁▁▁__________________________| max 28%, 0mm accumulation")
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
    expect(replies.last).to eq('Portland, OR, USA 24h fog report |▅▅▃____________________| visibility 9.12 km - 16 km')
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
    expect(replies.last).to eq("Portland, OR, USA 7day high/low temps 87.08°F |\u000304_▃\u000313🔥🔥🔥\u000305▇▅\u000304▅\u0003| 93.92°F / 56.12°F |\u000311_▅\u000308▇\u000307██\u000308▇▇▇\u0003| 67.46°F Range: 56.16°F - 108.41°F")
  end

  it '!ansitemp extremes' do
    mock_up '7dayextreme'
    send_command 'ansitemp'
    expect(replies.last).to eq("Portland, OR, USA 24 hr temps: 86.36°F (feels like 86.27°F) |04▇13🔥🔥07▅▅▅08▅▃▃▃▁▁11_08▁▁▃▃07▅▅▅▅04▇▇| 88.52°F  Range: 64.76°F - 102.2°F")
  end
end
