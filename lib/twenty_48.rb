# frozen_string_literal: true

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.setup

PROJECT_ROOT = File.dirname(File.absolute_path(__FILE__))

module Twenty48
  DRAW_CHAR = 'x'
  BOARD_CELL_X_COUNT = 4
  BOARD_CELL_Y_COUNT = 4
  BORDER_AND_PADDING = 1
  DISPLAY_WIDTH = 45
  DISPLAY_HEIGHT = 36
  COMMAND_LINE_USAGE = <<~QUOTE
    \n\nUSAGE\n\n
    twenty_48 --ncurses launches interactive terminal app using ncurses library as app display driver. Requires the presence of the "curses" gem
    twenty_48 --tty-cursor launches interactive terminal app using tty-cursor as app display driver
    twenty_48 --basic basic non-interactive REPL app\n\n
  QUOTE
  CURSES_DRIVER_USAGE = <<~QUOTE
    \n\nThis driver requires the curses gem which utilizes gem native C extensions.
    To use this driver you must first install the curses gem. Run 'gem install curses'
  QUOTE
  APP_USAGE = <<~QUOTE
    Command         Description

    ↑               Up
    ↓               Down
    ←               Left
    →               Right
    U               Undo
    N               New
    Q               Quit

  QUOTE
  PROMPT = "> "

  def self.launch(arg)
    case arg
    when '--ncurses'
      begin
        require 'curses'
      rescue LoadError
      end

      if defined?(Curses)
        require_relative 'twenty_48/display/curses_display_adapter.rb'
        App.run(Display::CursesDisplayAdapter.new)
      else
        puts CURSES_DRIVER_USAGE
        puts COMMAND_LINE_USAGE
      end
    when '--tty-cursor', nil
      require_relative 'twenty_48/display/t_t_y_display_adapter.rb'
      App.run(Display::TTYDisplayAdapter.new)
    else
      puts COMMAND_LINE_USAGE
    end
  rescue => e
    puts "A fatal exception has occurred"
    $stderr.puts e.full_message
  end
end
