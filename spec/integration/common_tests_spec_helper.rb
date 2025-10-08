# frozen_string_literal: true

shared_examples 'shows small screen error' do
  let(:display_width) { 130 }
  let(:display_height) { 20 }

  it 'shows small screen error' do
    pending
    stdout, _stderr = simulate_input('C 100 100')
    expect(stdout).to(include('Your terminal size 130x20 is smaller than the minimum required 22x22. '\
'Please resize your terminal'))
  end
end

