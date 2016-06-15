require_relative '../../spec_helper'
require 'geocoder'

describe Lita::Handlers::OnewheelForecastIo, lita_handler: true do

  before(:each) do
    Geocoder.configure(:lookup => :test)

    Geocoder::Lookup::Test.add_stub(
        'Portland, OR', [
        {
            'formatted_address' => 'Portland, OR, USA',

            'geometry' => {
                'location' => {
                    'lat'     => 45.523452,
                    'lng'    => -122.676207,
                    'address'      => 'Portland, OR, USA',
                    'state'        => 'Oregon',
                    'state_code'   => 'OR',
                    'country'      => 'United States',
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
                    'lat'     => 45.523452,
                    'lng'    => -122.676207,
                    'address'      => 'Portland, OR, USA',
                    'state'        => 'Oregon',
                    'state_code'   => 'OR',
                    'country'      => 'United States',
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
                    'lat'     => 45.523452,
                    'lng'    => -122.676207,
                    'address'      => 'Portland, OR, USA',
                    'state'        => 'Oregon',
                    'state_code'   => 'OR',
                    'country'      => 'United States',
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
                    'lat'     => 48.856614,
                    'lng'     => 2.3522219,
                    'address'      => 'Paris, FR',
                    'state'        => 'm',
                    'state_code'   => 'm',
                    'country'      => 'France',
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
                    'lat'     => 48.856614,
                    'lng'    => 2.3522219,
                    'address'      => 'Paris, FR',
                    'state'        => 'm',
                    'state_code'   => 'm',
                    'country'      => 'France',
                    'country_code' => 'FR'
                }
            }
        }
      ]
    )

    # Mock up the ForecastAPI call.
    # Todo: add some other mocks to allow more edgy testing (rain percentages, !rain eightball replies, etc
    mock_weather_json = File.open('spec/fixtures/mock_weather.json').read
    allow(RestClient).to receive(:get) { mock_weather_json }

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
    expect(replies.last).to eq("Portland, OR weather is currently 28.39°F and clear.  Winds out of the E at 5.74 mph. It will be clear for the hour, and flurries tomorrow morning.  There are also 357.71 ozones.")
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
    allow(RestClient).to receive(:get) { File.open('spec/fixtures/mock_weather_no_minute.json').read }
    send_command 'ansirain'
    expect(replies.last).to include('|No minute-by-minute data available.|')
  end

  it '!ansiintensity no minutes' do
    allow(RestClient).to receive(:get) { File.open('spec/fixtures/mock_weather_no_minute.json').read }
    send_command 'ansiintensity'
    expect(replies.last).to include('|No minute-by-minute data available.|')
  end

  it '!ansisnow Paris' do
    send_command 'ansisnow Paris'
    expect(replies.last).to include("|\u000302_❄\u000306▃\u000310▅\u000303▅\u000309▅\u000311▇\u000308▇\u000307█\u000304█\u000313█\u000302__________________________________________________\u0003|")
  end

  it '!ansiintensity' do
    send_command 'ansiintensity'
    expect(replies.last).to include("|\u000302_\u000313▅\u000310▁\u000303▃\u000309▃\u000311▃\u000308▅\u000307▅\u000304▅\u000313▅\u000302___________________________________________________\u0003|")
  end

  it '!ansitemp portland' do
    send_command 'ansitemp portland'
    expect(replies.last).to eq("Portland, OR, USA 24 hr temps: 28.3°F |\u000306_▁▃\u000310▅▇█\u000303██\u000310██▇▅\u000306▅▃▃▃▃▃▃▁▁▁▁\u0003| 28.4°F  Range: 28.3°F - 39.0°F")
  end

  it '!ieeetemp portland' do
    send_command 'ieeetemp portland'
    expect(replies.last).to eq("Portland, OR, USA 24 hr temps: 271.09K |\u000306_▁▃\u000310▅▇█\u000303██\u000310██▇▅\u000306▅▃▃▃▃▃▃▁▁▁▁\u0003| 271.15K  Range: 271.09K - 277.04K")
  end

  it '!dailytemp portland' do
    send_command 'dailytemp portland'
    expect(replies.last).to eq("Portland, OR, USA 48 hr temps: 28.3°F |\u000306_▁▃\u000310▅▅▇\u000303██\u000310▇▇▅▅\u000306▅▃▃▃▃▃▁▁▁▁▁▁▁▃\u000310▅▅▇\u000303█████▇\u000310▇▇▇▅▅▅▅\u000306▅▃▃▃▃\u0003| 30.5°F  Range: 28.3°F - 41.3°F")
  end

  it '!ansiwind portland' do
    send_command 'ansiwind portland'
    expect(replies.last).to eq("Portland, OR, USA 48h wind direction 4.3 mph|\u000306↓\u000310↙←\u000311↖↑↗\u000308→↘\u000311↓←←←←←←\u000310←←←←←←←\u000306←←←←←\u000302←←←↙↙↙↙↓↓↓\u000306↓↓↓↓↓↓↓↓↙↙\u0003|4.18 mph Range: 1.39 mph - 12.71 mph")
  end

  it '!conditions' do
    send_command 'conditions'
    expect(replies.last).to eq("Portland, OR 28.3°F |\u000306_▁▃\u000310▅▇█\u000303█\u0003| 38.72°F / 4.3 mph |\u000306↓\u000310↙←\u000311↖↑↗\u000308→\u0003| 12.71 mph / 98% chance of sun / 60m precip |\u000306❄\u000311▇\u000308▇\u000302_____________\u0003|")
  end

  it '!alerts' do
    send_command 'alerts'
    expect(replies.last).to eq("http://alerts.weather.gov/cap/wwacapget.php?x=OR125178E80B44.WindAdvisory.12517D235B00OR.PQRNPWPQR.95d9377231cf71049aacb48282406c60\nhttp://alerts.weather.gov/cap/wwacapget.php?x=OR125178E7B298.SpecialWeatherStatement.12517D218640OR.PQRSPSPQR.53656f1fdba795381a7895d7e3d153f7\n")
  end

  it '!ansisun' do
    send_command 'ansisun'
    expect(replies.last).to eq("Portland, OR 48hr sun forecast |\u000308████████████████████\u000307▇▇▅\u000309▅▅▃\u000303▁_▁\u000309▃▃▃\u000303▁▁▁▁▃\u000309▃▅\u000307▇▇▇▇\u000308▇▇▇▇▇▇\u0003| max 88%")
  end

  it '!dailysun' do
    send_command 'dailysun'
    expect(replies.last).to eq("Portland, OR 8 day sun forecast |\u000308█\u000309▃\u000308▇\u000309▁_\u000307▅\u000309▃\u000307▅\u0003| max 76%")
  end

  it '!asciisun' do
    send_command 'asciisun'
    expect(replies.last).to eq("Portland, OR 48hr sun forecast |\u000308''''''''''''''''''''\u000307**~\u000309~~-\u000303._.\u000309---\u000303....-\u000309-~\u000307****\u000308******\u0003| max 88%")
  end

  it '!ansicloud' do
    send_command 'ansicloud'
    expect(replies.last).to eq('Portland, OR 24h cloud cover |___________▁▁▁▁▁▁▁▁▃▅▅▅| range 0% - 49.0%')
  end

  it '!asciicloud' do
    send_command 'asciicloud'
    expect(replies.last).to eq('Portland, OR 24h cloud cover |___________........-~~~| range 0% - 49.0%')
  end

  it '!asciitemp' do
    send_command 'asciitemp'
    expect(replies.last).to eq("Portland, OR 24 hr temps: 28.3°F |\u000306_.-\u000310~*'\u000303''\u000310''*~\u000306~------....\u0003| 28.4°F  Range: 28.3°F - 39.0°F")
  end

  it '!asciirain' do
    send_command 'asciirain'
    expect(replies.last).to include("|\u000302_❄\u000306-\u000310~\u000303~\u000309~\u000311*\u000308*\u000307'\u000304'\u000313'\u000302__________________________________________________\u0003|")
  end

  it '!7day' do
    send_command '7day'
    expect(replies.last).to eq("Portland, OR 7day high/low temps 39.0°F |\u000303_▃\u000309▅\u000303▅\u000309▅███\u0003| 52.4°F / 28.2°F |\u000306_▁▃\u000310▅\u000303█\u000310▇\u000303██\u0003| 39.7°F Range: 28.17°F - 52.38°F")
  end

  it '!dailyrain' do
    send_command 'dailyrain'
    expect(replies.last).to eq("Portland, OR 48 hr snows |\u000302_______________________❄❄❄❄▁▁▁▁▁▁▁▁▁▁▁▁▁❄❄❄❄❄❄❄❄_\u0003| max 4.0%")
  end

  it '!7dayrain' do
    send_command '7dayrain'
    expect(replies.last).to eq("Portland, OR 7day snows |\u000302_▁▁\u000306▃\u000313█\u000303▅▅\u000310▃\u0003| max 100%")
  end

  it '!ansiozone' do
    send_command 'ansiozone'
    expect(replies.last).to eq("Portland, OR ozones 357.98 |??????????◉◉◉??????????◉◉◉◉◉◉◉◉◉◉◉◉◉◉◉◉◉◎◎◎◎◎◎◎◎◎| 330.44 [24h forecast]")
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
    expect(replies.last).to eq("Portland, OR 24 hr temps: 28.3°F |\u000306_▁▃\u000310▅▇█\u000303██\u000310██▇▅\u000306▅▃▃▃▃▃▃▁▁▁▁\u0003| 28.4°F  Range: 28.3°F - 39.0°F")
  end

  it '!ansitemp in k' do
    send_command 'set scale k'
    send_command 'ansitemp'
    expect(replies.last).to eq("Portland, OR 24 hr temps: 271.09K |\u000306_▁▃\u000310▅▇█\u000303██\u000310██▇▅\u000306▅▃▃▃▃▃▃▁▁▁▁\u0003| 271.15K  Range: 271.09K - 277.04K")
  end

  it '!ansitemp in K' do
    send_command 'set scale K'
    send_command 'ansitemp'
    expect(replies.last).to eq("Portland, OR 24 hr temps: 271.09K |\u000306_▁▃\u000310▅▇█\u000303██\u000310██▇▅\u000306▅▃▃▃▃▃▃▁▁▁▁\u0003| 271.15K  Range: 271.09K - 277.04K")
  end

  it '!ansitemp in C' do
    send_command 'set scale c'
    send_command 'ansitemp'
    expect(replies.last).to eq("Portland, OR 24 hr temps: -2.06°C |\u000306_▁▃\u000310▅▇█\u000303██\u000310██▇▅\u000306▅▃▃▃▃▃▃▁▁▁▁\u0003| -2.0°C  Range: -2.06°C - 3.89°C")
  end

  it '!ansiwind in MPH' do
    send_command 'set scale f'
    send_command 'ansiwind'
    expect(replies.last).to include("1.39 mph - 12.71 mph")
  end

  it '!ansiwind in KPH' do
    send_command 'set scale c'
    send_command 'ansiwind'
    expect(replies.last).to include("2.22 kph - 20.34 kph")
  end

  it '!sunrise' do
    send_command 'sunrise'
    expect(replies.last).to include("Portland, OR sunrise: ")
  end

  it '!sunset' do
    send_command 'sunset'
    expect(replies.last).to include("Portland, OR sunset: ")
  end

  it '!dailywind' do
    send_command 'dailywind'
    expect(replies.last).to eq("Portland, OR 7day winds 7.67 mph|\u000310█\u000306▅\u000310██\u000302▅▅▅\u000306▅\u0003|3.02 mph range 2.67 mph-7.67 mph")
  end

  it '!ansihumidity' do
    send_command 'ansihumidity'
    expect(replies.last).to eq("Portland, OR 48hr humidity 67%|\u000307▇\u000308▇▇▇\u000311▅▅▅▅▅▅▅▅▅▅\u000308▇▇▇▇▇▇▇\u000307▇▇▇▇▇▇▇▇▇▇▇▇\u000304████████████████\u0003|80% range: 41%-85%")
  end

  it '!dailyhumidity' do
    send_command 'dailyhumidity'
    expect(replies.last).to eq("Portland, OR 7day humidity 58%|\u000302▇▇▇▇████\u0003|87% range 58%-93%")
  end

  it '!forecastallthethings' do
    send_command 'forecastallthethings'
    expect(replies[0]).to eq("Portland, OR weather is currently 28.39°F and clear.  Winds out of the E at 5.74 mph. It will be clear for the hour, and flurries tomorrow morning.  There are also 357.71 ozones.")
    expect(replies[1]).to include("|\u000302_❄\u000306▃\u000310▅\u000303▅\u000309▅\u000311▇\u000308▇\u000307█\u000304█\u000313█\u000302__________________________________________________\u0003|")
    expect(replies[2]).to include("|\u000302_\u000313▅\u000310▁\u000303▃\u000309▃\u000311▃\u000308▅\u000307▅\u000304▅\u000313▅\u000302___________________________________________________\u0003|")
    expect(replies[3]).to eq("Portland, OR 24 hr temps: 28.3°F |\u000306_▁▃\u000310▅▇█\u000303██\u000310██▇▅\u000306▅▃▃▃▃▃▃▁▁▁▁\u0003| 28.4°F  Range: 28.3°F - 39.0°F")
    expect(replies[4]).to eq("Portland, OR 48h wind direction 4.3 mph|\u000306↓\u000310↙←\u000311↖↑↗\u000308→↘\u000311↓←←←←←←\u000310←←←←←←←\u000306←←←←←\u000302←←←↙↙↙↙↓↓↓\u000306↓↓↓↓↓↓↓↓↙↙\u0003|4.18 mph Range: 1.39 mph - 12.71 mph")
    expect(replies[5]).to eq("Portland, OR 48hr sun forecast |\u000308████████████████████\u000307▇▇▅\u000309▅▅▃\u000303▁_▁\u000309▃▃▃\u000303▁▁▁▁▃\u000309▃▅\u000307▇▇▇▇\u000308▇▇▇▇▇▇\u0003| max 88%")
    expect(replies[6]).to eq("Portland, OR 24h cloud cover |████████████████████▇▇▇| range 51.0% - 100.0%")
    expect(replies[7]).to eq("Portland, OR 48 hr snows |\u000302_______________________❄❄❄❄▁▁▁▁▁▁▁▁▁▁▁▁▁❄❄❄❄❄❄❄❄_\u0003| max 4.0%")
  end

  it '!ansipressure' do
    send_command 'ansipressure'
    expect(replies.last).to eq("Portland, OR pressure 1021.2 hPa |████▇▅▅▃▃▃▃▅▇▇▇▇▇▅▅▅▅▅▃▃▃▃▅▅▅▃▁▁▁__▁▁▃▃▅▅▅▅▅▃▁▁▁▃| 1018.31 hPa range: 1017.96-1021.2 hPa [48h forecast]")
  end

  it '!ansibarometer' do
    send_command 'ansibarometer'
    expect(replies.last).to eq("Portland, OR pressure 1021.2 hPa |████▇▅▅▃▃▃▃▅▇▇▇▇▇▅▅▅▅▅▃▃▃▃▅▅▅▃▁▁▁__▁▁▃▃▅▅▅▅▅▃▁▁▁▃| 1018.31 hPa range: 1017.96-1021.2 hPa [48h forecast]")
  end

  it '!dailypressure' do
    send_command 'dailypressure'
    expect(replies.last).to eq("Portland, OR pressure 1019.92 hPa |▅▅▃_▁▇██| 1027.26 hPa range: 1013.45-1027.26 hPa [8 day forecast]")
  end

  it '!dailybarometer' do
    send_command 'dailybarometer'
    expect(replies.last).to eq("Portland, OR pressure 1019.92 hPa |▅▅▃_▁▇██| 1027.26 hPa range: 1013.45-1027.26 hPa [8 day forecast]")
  end

  it '!asciiwind' do
    send_command 'asciiwind'
    expect(replies.last).to eq("Portland, OR 48h wind direction 4.3 mph|\u000306v\u000310,<\u000311\\^/\u000308>.\u000311v<<<<<<\u000310<<<<<<<\u000306<<<<<\u000302<<<,,,,vvv\u000306vvvvvvvv,,\u0003|4.18 mph Range: 1.39 mph - 12.71 mph")
  end
  
  it '!geo' do
    send_command 'geo Paris, france'
    expect(replies.last).to eq('48.856614, 2.3522219')
  end

  it '!neareststorm' do
    send_command 'neareststorm'
    expect(replies.last).to eq('The nearest storm is 158 mi to the S of you.')
  end

  it '!neareststorm is zero' do
    mock_weather_json = File.open('spec/fixtures/heavy_rain.json').read
    allow(RestClient).to receive(:get) { mock_weather_json }

    send_command 'neareststorm'
    expect(replies.last).to eq('You\'re in it!')
  end

  it '!neareststorm with scale' do
    send_command 'set scale c'
    send_command 'neareststorm'
    expect(replies.last).to eq('The nearest storm is 252.8 km to the S of you.')
  end

  # it 'colors strings' do
    # cstr = Lita::Handlers::ForecastIo.get_colored_string([{:key => 1}], :key, 'x', {1 => :blue})
    # expect(cstr).to equal('x')
  # end
end
