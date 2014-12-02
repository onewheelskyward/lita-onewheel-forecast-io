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
    end
  end

  # Todo: mock weather data for predictable output.

  it { is_expected.to route('!forecast') }
  it { is_expected.to route('!weather') }
  it { is_expected.to route('!rain') }
  it { is_expected.to route('!ansirain') }
  it { is_expected.to route('!ansisnow') }
  it { is_expected.to route('!ansiintensity') }
  it { is_expected.to route('!ansitemp') }
  it { is_expected.to route('!ansiwind') }
  it { is_expected.to route('!ansisun') }
  it { is_expected.to route('!ansicloud') }
  it { is_expected.to route('!7day') }
  it { is_expected.to route('!dailyrain') }
  it { is_expected.to route('!alerts') }
  it { is_expected.to route('!ansiozone') }
  it { is_expected.to route('!set scale f') }
  it { is_expected.to route('!set scale c') }

  it '!forecast' do
    send_message '!forecast'
    expect(replies.last).to eq("Portland, OR weather is currently 28.39°F and clear.  Winds out of the E at 5.74 mph. It will be clear for the hour, and flurries tomorrow morning.  There are also 357.71 ozones.")
  end

  it '!rain' do
    allow(MagicEightball).to receive(:reply) { 'Nope' }
    send_message '!rain Portland'
    expect(replies.last).to eq('Nope')
  end

  it '!ansirain Paris' do
    send_message '!ansirain Paris'
    expect(replies.last).to include("|\u000302_▁\u000306▃\u000310▅\u000303▅\u000309▅\u000311▇\u000308▇\u000307█\u000304█\u000313█\u000302__________________________________________________\u0003|")
  end

  it '!ansiintensity' do
    send_message '!ansiintensity'
    expect(replies.last).to include("|\u000302_\u000313▁\u000310▁\u000303▁\u000309▁\u000311▁\u000308▁\u000307▁\u000304▁\u000313▁\u000302___________________________________________________\u0003|")
  end

  it '!ansitemp portland' do
    send_message '!ansitemp portland'
    expect(replies.last).to eq("Portland, OR temps: now 28.3°F |\u000306_▁▃\u000310▅▇█\u000303██\u000310██▇▅\u000306▅▃▃▃▃▃▃▁▁▁▁\u0003| 28.4°F this hour tomorrow.  Range: 28.3°F - 39.0°F")
  end

  it '!ansiwind portland' do
    send_message '!ansiwind portland'
    expect(replies.last).to eq("Portland, OR 24h wind direction |\u000306↓\u000310↙←\u000311↖↑↗\u000308→↘\u000311↓←←←←←←\u000310←←←←←←←\u000306←\u0003| Range: 4.3 mph - 12.71 mph")
  end

  it '!conditions' do
    send_message '!conditions'
    expect(replies.last).to eq("Portland, OR 28.3°F |\u000306_▁▃\u000310▅▇█\u000303█\u0003| 38.72°F / 4.3 mph |\u000306↓\u000310↙←\u000311↖↑↗\u000308→\u0003| 12.71 mph / 98% chance of sun / 60m rain |\u0003▁▃▅▅▅▇▇███_____________|")
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

  it '!7day' do
    send_message '!7day'
    expect(replies.last).to eq("Portland, OR 7day high/low temps 39.0°F |\u000303_▃\u000309▅\u000303▅\u000309▅███\u0003| 52.4°F / 28.2°F |\u000306_▁▃\u000310▅\u000303█\u000310▇\u000303██\u0003| 39.7°F Range: 28.17°F - 52.38°F")
  end

  it '!dailyrain' do
    send_message '!dailyrain'
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

  it '!set scale already set' do
    send_message '!set scale f'
    send_message '!set scale f'
    expect(replies.last).to eq("Scale is already set to f!")
  end

  it '!set scale c' do
    send_message '!set scale c'
    expect(replies.last).to eq("Scale set to c")
  end

  # it 'colors strings' do
    # cstr = Lita::Handlers::ForecastIo.get_colored_string([{:key => 1}], :key, 'x', {1 => :blue})
    # expect(cstr).to equal('x')
  # end
end
