# frozen_string_literal: true

require 'spec_helper'

context 'invocation ' do
  before { stub_const 'ARGV', arguments }

  subject { load File.join(PROJECT_ROOT, '../bin/twenty-48') }

  context 'bad arguments' do
    let(:arguments) { %w(--illegal-argument) }

    it 'shows command line usage prompt' do
      expect { subject }.to(output(Twenty48::COMMAND_LINE_USAGE).to_stdout)
    end
  end

  context '--tty-cursor' do
    let(:arguments) { %w(--tty-cursor) }
    before { require File.join(PROJECT_ROOT, '/twenty_48/display/t_t_y_display_adapter.rb') }

    it 'launches Interactive App with tty_cursor display adapter' do
      display_instance_stub = instance_double(Twenty48::Display::TTYDisplayAdapter)
      class_double(Twenty48::Display::TTYDisplayAdapter, new: display_instance_stub).as_stubbed_const

      expect(Twenty48::App).to(receive(:run).with(display_instance_stub))

      expect { subject }.to_not(output.to_stdout)
    end
  end

  context '--ncurses', :requires_curses do
    let(:arguments) { %w(--ncurses) }

    before { require File.join(PROJECT_ROOT, '/twenty_48/display/curses_display_adapter.rb') }

    it 'launches Interactive App with tty_cursor display adapter' do
      display_instance_stub = instance_double(Twenty48::Display::CursesDisplayAdapter)
      class_double(Twenty48::Display::CursesDisplayAdapter, new: display_instance_stub).as_stubbed_const

      expect(Twenty48::App).to(receive(:run).with(display_instance_stub))

      expect { subject }.to_not(output.to_stdout)
    end
  end
end
