require_relative '../../spec_helper'

describe Lita::Handlers::ForecastIo, lita_handler: true do
  # it { is_expected.to route("some message") }
  # it 'lets everyone know when someone is happy' do
  #   send_message("I'm happy!")
  #   expect(replies.last).to eq("Hey, everyone! #{user.name} is happy! Isn't that nice?")
  # end
  before(:each) do
    mock_geocoder = ::Geocoder::Result::Google.new({'formatted_address' => 'Portland, OR', 'geometry' => { 'location' => { 'lat' => 45.523452, 'lng' => -122.676207 }}})
    allow(::Geocoder).to receive(:search) { [mock_geocoder] }  # It expects an array of geocoder objects.

    # Mock up the ForecastAPI call.
    # Todo: add some other mocks to allow more edgy testing (rain percentages, !rain eightball replies, etc
    mock_weather_json = File.open("spec/mock_weather.json").read
    allow(RestClient).to receive(:get) { mock_weather_json }

    registry.configure do |config|
      config.handlers.forecast_io.api_uri = 'https://api.forecast.io/forecast/'
      config.handlers.forecast_io.api_key = '5537a6b7a8e2936dc7ced091b999d60a'
      config.handlers.forecast_io.colors = true
    end
  end

  it { is_expected.to route('!forecast') }
  it { is_expected.to route('!weather') }
  it { is_expected.to route('!rain') }
  it { is_expected.to route('!snow') }
  it { is_expected.to route('!ansirain') }
  it { is_expected.to route('!ansisnow') }
  it { is_expected.to route('!ansihumidity') }
  it { is_expected.to route('!ansiintensity') }
  it { is_expected.to route('!ansitemp') }
  it { is_expected.to route('!ansiwind') }
  it { is_expected.to route('!asciiwind') }
  it { is_expected.to route('!ansisun') }
  it { is_expected.to route('!ansicloud') }
  it { is_expected.to route('!asciitemp') }
  it { is_expected.to route('!asciirain') }
  it { is_expected.to route('!7day') }
  it { is_expected.to route('!weekly') }
  it { is_expected.to route('!dailyrain') }
  it { is_expected.to route('!dailysnow') }
  it { is_expected.to route('!dailytemp') }
  it { is_expected.to route('!dailyhumidity') }
  it { is_expected.to route('!7dayrain') }
  it { is_expected.to route('!weeklyrain') }
  it { is_expected.to route('!weeklysnow') }
  it { is_expected.to route('!dailywind') }
  it { is_expected.to route('!alerts') }
  it { is_expected.to route('!ansiozone') }
  it { is_expected.to route('!cond') }
  it { is_expected.to route('!condi') }
  it { is_expected.to route('!condit') }
  it { is_expected.to route('!conditi') }
  it { is_expected.to route('!conditio') }
  it { is_expected.to route('!condition') }
  it { is_expected.to route('!conditions') }
  it { is_expected.to route('!set scale f') }
  it { is_expected.to route('!set scale c') }
  it { is_expected.to route('!set scale k') }
  it { is_expected.to route('!set scale') }
  it { is_expected.to route('!sunrise') }
  it { is_expected.to route('!sunset') }
  it { is_expected.to route('!forecastallthethings') }
  it { is_expected.to route('!ansipressure') }
  it { is_expected.to route('!ansibarometer') }
  it { is_expected.to route('!dailypressure') }
  it { is_expected.to route('!dailybarometer') }

  # This is where we test for regex overflow, so !weeklyrain doesn't try to get a forecast for Rain, Germany.
  it { is_expected.not_to route('!forecastrain') }
  it { is_expected.not_to route('!weatherrain') }
  it { is_expected.not_to route('!rainrain') }
  it { is_expected.not_to route('!snowrain') }
  it { is_expected.not_to route('!ansirainrain') }
  it { is_expected.not_to route('!ansisnowrain') }
  it { is_expected.not_to route('!ansihumidityrain') }
  it { is_expected.not_to route('!ansiintensityrain') }
  it { is_expected.not_to route('!ansitemprain') }
  it { is_expected.not_to route('!ansiwindrain') }
  it { is_expected.not_to route('!asciiwindrain') }
  it { is_expected.not_to route('!ansisunrain') }
  it { is_expected.not_to route('!ansicloudrain') }
  it { is_expected.not_to route('!asciitemprain') }
  it { is_expected.not_to route('!asciirainrain') }
  it { is_expected.not_to route('!dailyrainrain') }
  it { is_expected.not_to route('!dailysnowrain') }
  it { is_expected.not_to route('!dailytemprain') }
  it { is_expected.not_to route('!dailyhumidityrain') }
  it { is_expected.not_to route('!7dayrainrain') }
  it { is_expected.not_to route('!weeklyrainrain') }
  it { is_expected.not_to route('!weeklysnowrain') }
  it { is_expected.not_to route('!dailywindrain') }
  it { is_expected.not_to route('!alertsrain') }
  it { is_expected.not_to route('!ansiozonerain') }
  it { is_expected.not_to route('!condrain') }
  it { is_expected.not_to route('!condirain') }
  it { is_expected.not_to route('!conditrain') }
  it { is_expected.not_to route('!conditirain') }
  it { is_expected.not_to route('!conditiorain') }
  it { is_expected.not_to route('!conditionrain') }
  it { is_expected.not_to route('!conditionsrain') }
  it { is_expected.not_to route('!sunriserain') }
  it { is_expected.not_to route('!sunsetrain') }
  it { is_expected.not_to route('!forecastallthethingsrain') }
  it { is_expected.not_to route('!ansipressurerain') }
  it { is_expected.not_to route('!ansibarometerrain') }
  it { is_expected.not_to route('!dailypressurerain') }
  it { is_expected.not_to route('!dailybarometerrain') }

  it '!forecast' do
    send_message '!forecast'
    expect(replies.last).to eq("Portland, OR weather is currently 28.39°F and clear.  Winds out of the E at 5.74 mph. It will be clear for the hour, and flurries tomorrow morning.  There are also 357.71 ozones.")
  end

  it '!rain' do
    allow(MagicEightball).to receive(:reply) { 'Nope' }
    send_message '!rain Portland'
    expect(replies.last).to eq('Nope')
  end

  it '!snow' do
    allow(MagicEightball).to receive(:reply) { 'Nope' }
    send_message '!snow Portland'
    expect(replies.last).to eq('Nope')
  end

  it '!ansirain Paris' do
    send_message '!ansirain Paris'
    expect(replies.last).to include("|\u000302_☃\u000306▃\u000310▅\u000303▅\u000309▅\u000311▇\u000308▇\u000307█\u000304█\u000313█\u000302__________________________________________________\u0003|")
  end

  it '!ansisnow Paris' do
    send_message '!ansisnow Paris'
    expect(replies.last).to include("|\u000302_☃\u000306▃\u000310▅\u000303▅\u000309▅\u000311▇\u000308▇\u000307█\u000304█\u000313█\u000302__________________________________________________\u0003|")
  end

  it '!ansiintensity' do
    send_message '!ansiintensity'
    expect(replies.last).to include("|\u000302_\u000313?\u000310▃\u000303▅\u000309▅\u000311▇\u000308▇\u000307█\u000304█\u000313?\u000302___________________________________________________\u0003|")
  end

  it '!ansitemp portland' do
    send_message '!ansitemp portland'
    expect(replies.last).to eq("Portland, OR 24 hr temps: 28.3°F |\u000306_▁▃\u000310▅▇█\u000303██\u000310██▇▅\u000306▅▃▃▃▃▃▃▁▁▁▁\u0003| 28.4°F  Range: 28.3°F - 39.0°F")
  end

  it '!dailytemp portland' do
    send_message '!dailytemp portland'
    expect(replies.last).to eq("Portland, OR 48 hr temps: 28.3°F |\u000306_▁▃\u000310▅▅▇\u000303██\u000310▇▇▅▅\u000306▅▃▃▃▃▃▁▁▁▁▁▁▁▃\u000310▅▅▇\u000303█████▇\u000310▇▇▇▅▅▅▅\u000306▅▃▃▃▃\u0003| 30.5°F  Range: 28.3°F - 41.3°F")
  end

  it '!ansiwind portland' do
    send_message '!ansiwind portland'
    expect(replies.last).to eq("Portland, OR 48h wind direction 4.3 mph|\u000306↓\u000310↙←\u000311↖↑↗\u000308→↘\u000311↓←←←←←←\u000310←←←←←←←\u000306←←←←←\u000302←←←↙↙↙↙↓↓↓\u000306↓↓↓↓↓↓↓↓↙↙\u0003|4.18 mph Range: 1.39 mph - 12.71 mph")
  end

  it '!conditions' do
    send_message '!conditions'
    expect(replies.last).to eq("Portland, OR 28.3°F |\u000306_▁▃\u000310▅▇█\u000303█\u0003| 38.72°F / 4.3 mph |\u000306↓\u000310↙←\u000311↖↑↗\u000308→\u0003| 12.71 mph / 98% chance of sun / 60m precip |_▅█_____________|")
  end

  it '!alerts' do
    send_message '!alerts'
    expect(replies.last).to eq("http://alerts.weather.gov/cap/wwacapget.php?x=OR125178E80B44.WindAdvisory.12517D235B00OR.PQRNPWPQR.95d9377231cf71049aacb48282406c60\nhttp://alerts.weather.gov/cap/wwacapget.php?x=OR125178E7B298.SpecialWeatherStatement.12517D218640OR.PQRSPSPQR.53656f1fdba795381a7895d7e3d153f7\n")
  end

  it '!ansisun' do
    send_message '!ansisun'
    expect(replies.last).to eq("Portland, OR 8 day sun forecast |\u000308█\u000309▃\u000308▇\u000309▁_\u000307▅\u000309▃\u000307▅\u0003|")
  end

  it '!ansicloud' do
    send_message '!ansicloud'
    expect(replies.last).to eq('Portland, OR 24h cloud cover |___________▁▁▁▁▁▁▁▁▃▅▅▅|')
  end

  it '!asciitemp' do
    send_message '!asciitemp'
    expect(replies.last).to eq("Portland, OR 24 hr temps: 28.3°F |\u000306_.-\u000310~*'\u000303''\u000310''*~\u000306~------....\u0003| 28.4°F  Range: 28.3°F - 39.0°F")
  end

  it '!asciirain' do
    send_message '!asciirain'
    expect(replies.last).to include("|\u000302_☃\u000306-\u000310~\u000303~\u000309~\u000311*\u000308*\u000307'\u000304'\u000313'\u000302__________________________________________________\u0003|")
  end

  it '!7day' do
    send_message '!7day'
    expect(replies.last).to eq("Portland, OR 7day high/low temps 39.0°F |\u000303_▃\u000309▅\u000303▅\u000309▅███\u0003| 52.4°F / 28.2°F |\u000306_▁▃\u000310▅\u000303█\u000310▇\u000303██\u0003| 39.7°F Range: 28.17°F - 52.38°F")
  end

  it '!dailyrain' do
    send_message '!dailyrain'
    expect(replies.last).to eq("Portland, OR 48 hr snows |\u000302_______________________▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁_\u0003|")
  end

  it '!7dayrain' do
    send_message '!7dayrain'
    expect(replies.last).to eq("Portland, OR 7day snows |\u000302_▁▁\u000306▃\u000313█\u000303▅▅\u000310▃\u0003|")
  end

  it '!ansiozone' do
    send_message '!ansiozone'
    expect(replies.last).to eq("Portland, OR ozones 357.98 |??????????◉◉◉??????????◉◉◉◉◉◉◉◉◉◉◉◉◉◉◉◉◉◎◎◎◎◎◎◎◎◎| 330.44 [24h forecast]")
  end

  it '!set scale f' do
    send_message '!set scale f'
    expect(replies.last).to eq("Scale set to f")
  end

  it '!set scale k' do
    send_message '!set scale k'
    expect(replies.last).to eq("Scale set to k")
  end

  it '!set scale already set' do
    send_message '!set scale f'
    send_message '!set scale f'
    expect(replies.last).to eq("Scale is already set to f!")
  end

  it '!set scale c' do
    send_message '!set scale c'
    expect(replies.last).to eq("Scale set to c")
  end

  it '!set scale toggle' do
    send_message '!set scale f'
    expect(replies.last).to eq("Scale set to f")
    send_message '!set scale'
    expect(replies.last).to eq("Scale set to c")
    send_message '!set scale'
    expect(replies.last).to eq("Scale set to f")
  end

  it '!ansitemp in F' do
    send_message '!set scale f'
    send_message '!ansitemp'
    expect(replies.last).to eq("Portland, OR 24 hr temps: 28.3°F |\u000306_▁▃\u000310▅▇█\u000303██\u000310██▇▅\u000306▅▃▃▃▃▃▃▁▁▁▁\u0003| 28.4°F  Range: 28.3°F - 39.0°F")
  end

  it '!ansitemp in k' do
    send_message '!set scale k'
    send_message '!ansitemp'
    expect(replies.last).to eq("Portland, OR 24 hr temps: 271.09K |\u000306_▁▃\u000310▅▇█\u000303██\u000310██▇▅\u000306▅▃▃▃▃▃▃▁▁▁▁\u0003| 271.15K  Range: 271.09K - 277.04K")
  end

  it '!ansitemp in K' do
    send_message '!set scale K'
    send_message '!ansitemp'
    expect(replies.last).to eq("Portland, OR 24 hr temps: 271.09K |\u000306_▁▃\u000310▅▇█\u000303██\u000310██▇▅\u000306▅▃▃▃▃▃▃▁▁▁▁\u0003| 271.15K  Range: 271.09K - 277.04K")
  end

  it '!ansitemp in C' do
    send_message '!set scale c'
    send_message '!ansitemp'
    expect(replies.last).to eq("Portland, OR 24 hr temps: -2.06°C |\u000306_▁▃\u000310▅▇█\u000303██\u000310██▇▅\u000306▅▃▃▃▃▃▃▁▁▁▁\u0003| -2.0°C  Range: -2.06°C - 3.89°C")
  end

  it '!ansiwind in MPH' do
    send_message '!set scale f'
    send_message '!ansiwind'
    expect(replies.last).to include("1.39 mph - 12.71 mph")
  end

  it '!ansiwind in KPH' do
    send_message '!set scale c'
    send_message '!ansiwind'
    expect(replies.last).to include("2.22 kph - 20.34 kph")
  end

  it '!sunrise' do
    send_message '!sunrise'
    expect(replies.last).to eq("Portland, OR sunrise: 07:30:58")
  end

  it '!sunset' do
    send_message '!sunset'
    expect(replies.last).to eq("Portland, OR sunset: 16:30:55")
  end

  it '!dailywind' do
    send_message '!dailywind'
    expect(replies.last).to eq("Portland, OR 7day winds 7.67 mph|\u000310█\u000306▅\u000310██\u000302▅▅▅\u000306▅\u0003|3.02 mph range 2.67 mph-7.67 mph")
  end

  it '!ansihumidity' do
    send_message '!ansihumidity'
    expect(replies.last).to eq("Portland, OR 48hr humidity 67%|\u000307▇\u000308▇▇▇\u000311▅▅▅▅▅▅▅▅▅▅\u000308▇▇▇▇▇▇▇\u000307▇▇▇▇▇▇▇▇▇▇▇▇\u000304████████████████\u0003|80% range: 41%-85%")
  end

  it '!dailyhumidity' do
    send_message '!dailyhumidity'
    expect(replies.last).to eq("Portland, OR 7day humidity 58%|\u000302▇▇▇▇████\u0003|87% range 58%-93%")
  end

  it '!forecastallthethings' do
    send_message '!forecastallthethings'
    expect(replies[0]).to eq("Portland, OR weather is currently 28.39°F and clear.  Winds out of the E at 5.74 mph. It will be clear for the hour, and flurries tomorrow morning.  There are also 357.71 ozones.")
    expect(replies[1]).to include("|\u000302_☃\u000306▃\u000310▅\u000303▅\u000309▅\u000311▇\u000308▇\u000307█\u000304█\u000313█\u000302__________________________________________________\u0003|")
    expect(replies[2]).to include("|\u000302_\u000313?\u000310▃\u000303▅\u000309▅\u000311▇\u000308▇\u000307█\u000304█\u000313?\u000302___________________________________________________\u0003|")
    expect(replies[3]).to eq("Portland, OR 24 hr temps: 28.3°F |\u000306_▁▃\u000310▅▇█\u000303██\u000310██▇▅\u000306▅▃▃▃▃▃▃▁▁▁▁\u0003| 28.4°F  Range: 28.3°F - 39.0°F")
    expect(replies[4]).to eq("Portland, OR 48h wind direction 4.3 mph|\u000306↓\u000310↙←\u000311↖↑↗\u000308→↘\u000311↓←←←←←←\u000310←←←←←←←\u000306←←←←←\u000302←←←↙↙↙↙↓↓↓\u000306↓↓↓↓↓↓↓↓↙↙\u0003|4.18 mph Range: 1.39 mph - 12.71 mph")
    expect(replies[5]).to eq("Portland, OR 8 day sun forecast |\u000308█\u000309▃\u000308▇\u000309▁_\u000307▅\u000309▃\u000307▅\u0003|")
    expect(replies[6]).to eq("Portland, OR 24h cloud cover |___________▁▁▁▁▁▁▁▁▃▅▅▅|")
    expect(replies[7]).to eq("Portland, OR 48 hr snows |\u000302_______________________▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁_\u0003|")
  end

  it '!ansipressure' do
    send_message '!ansipressure'
    expect(replies.last).to eq("Portland, OR pressure 1021.2 hPa |████▇▅▅▃▃▃▃▅▇▇▇▇▇▅▅▅▅▅▃▃▃▃▅▅▅▃▁▁▁__▁▁▃▃▅▅▅▅▅▃▁▁▁▃| 1018.31 hPa range: 1017.96-1021.2 hPa [48h forecast]")
  end

  it '!ansibarometer' do
    send_message '!ansibarometer'
    expect(replies.last).to eq("Portland, OR pressure 1021.2 hPa |████▇▅▅▃▃▃▃▅▇▇▇▇▇▅▅▅▅▅▃▃▃▃▅▅▅▃▁▁▁__▁▁▃▃▅▅▅▅▅▃▁▁▁▃| 1018.31 hPa range: 1017.96-1021.2 hPa [48h forecast]")
  end

  it '!dailypressure' do
    send_message '!dailypressure'
    expect(replies.last).to eq("Portland, OR pressure 1019.92 hPa |▅▅▃_▁▇██| 1027.26 hPa range: 1013.45-1027.26 hPa [8 day forecast]")
  end

  it '!dailybarometer' do
    send_message '!dailybarometer'
    expect(replies.last).to eq("Portland, OR pressure 1019.92 hPa |▅▅▃_▁▇██| 1027.26 hPa range: 1013.45-1027.26 hPa [8 day forecast]")
  end

  it '!asciiwind' do
    send_message '!asciiwind'
    expect(replies.last).to eq("Portland, OR 48h wind direction 4.3 mph|\u000306v\u000310,<\u000311\\^/\u000308>.\u000311v<<<<<<\u000310<<<<<<<\u000306<<<<<\u000302<<<,,,,vvv\u000306vvvvvvvv,,\u0003|4.18 mph Range: 1.39 mph - 12.71 mph")
  end
  
  it '!geo' do
    send_message '!geo Paris, france'
    expect(replies.last).to eq('45.523452, -122.676207')
  end

  # it 'colors strings' do
    # cstr = Lita::Handlers::ForecastIo.get_colored_string([{:key => 1}], :key, 'x', {1 => :blue})
    # expect(cstr).to equal('x')
  # end
end
