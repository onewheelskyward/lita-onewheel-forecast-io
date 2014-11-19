require_relative '../../spec_helper'

describe Lita::Handlers::ForecastIo, lita_handler: true do
  # it { is_expected.to route("some message") }
  # it 'lets everyone know when someone is happy' do
  #   send_message("I'm happy!")
  #   expect(replies.last).to eq("Hey, everyone! #{user.name} is happy! Isn't that nice?")
  # end
  it '!rain' do
    send_message '!rain'
    expect(replies.last).to eq 'no'
  end
end
