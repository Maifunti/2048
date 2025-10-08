# frozen_string_literal: true

require_relative './common_tests_spec_helper.rb'

describe 'Interactive app using CursesDisplayAdapter', :requires_curses do
  before(:all) { require 'support/test_cursor_display' }

  def simulate_input(string = nil)
    if string
      old_input_pos = test_display.test_input_io.pos
      test_display.test_input_io << string
      test_display.test_input_io.pos = old_input_pos
    end

    # run test
    subject.call

    test_display.get_captured_output
  end

  let(:display_width) { 100 }
  let(:display_height) { 100 }
  let(:test_display) { Test::CursesDisplay.build(display_width, display_height) }
  let(:test_app) { Twenty48::App.new(test_display) }

  after { Curses.close_screen }

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
