# frozen_string_literal: true

require_relative './common_tests_spec_helper.rb'

describe 'Interactive app using TTYDisplayAdapter' do
  # @return std_out and std_err outputs from running command string
  def simulate_input(string)
    old_input_pos = input_io.pos
    input_io << string
    input_io.pos = old_input_pos

    subject.call

    test_display.get_captured_output
  end

  let(:display_width) { 100 }
  let(:display_height) { 100 }
  let(:input_io) { StringIO.new }
  let(:out_io) { StringIO.new }
  let(:message) { StringIO.new }
  let(:test_display) { Test::TTYDisplayAdapter.build(display_width, display_height, input_io, out_io) }
  let(:test_app) { Twenty48::App.new(test_display) }

  subject { -> { test_app.run } }

  Dir.glob(RSPEC_ROOT + "/fixtures/interactive_app/*") do |test_fixture|
    it File.basename(test_fixture).to_s do
      command_text = File.open(RSPEC_ROOT + '/fixtures/integration/' + File.basename(test_fixture) + '/command.txt').read
      expectation_text = File.open(test_fixture + '/expectation.txt').read
      stdout = simulate_input(command_text)

      expect(stdout).to(eql(expectation_text))
    end
  end

  it_behaves_like 'shows small screen error'
end
