# frozen_string_literal: true

module Twenty48
  module Display
    # Uses manual manipulation of the terminal using IO print commands, ANSI escape, and ASCII control codes
    # This solution is less performant than CursesDisplayAdapter but does not require a native gem extension
    class TTYDisplayAdapter
      require 'tty-cursor'
      require 'tty-screen'
      require 'tty-reader'
      require 'io/console'
      require_relative 'editor.rb'
      require_relative '../os.rb'

      CSI = "\e["
      ENABLE_ALTERNATE_BUFFER = CSI + "?1049h"
      DISABLE_ALTERNATE_BUFFER = CSI + "?1049l"
      DISABLE_LINE_WRAP = CSI + "7l"
      ENABLE_LINE_WRAP = CSI + "7h"

      # TTY::Reader we're using will return ANSI escape codes or ASCII control codes
      BACKSPACE = ["\u007F", "\b"]
      ENTER = ["\r", "\n"]
      ESCAPE = ["\e", 27]
      LEFT = ["\e[D", "\u00E0K"]
      RIGHT = ["\e[C", "\u00E0M"]
      DOWN = ["\e[B", "\u00E0P"]
      UP = ["\e[A", "\u00E0H"]

      # Callers must call #close when finished
      def initialize(input = $stdin, output = $stdout)
        @input = input
        @output = output

        @reader = TTY::Reader.new(input: @input, output: @output, interrupt: :exit, track_history: false)

        initialize_screen

        @editor = Editor.new(self)

        # try to trap terminal resizes. Only works on systems that support SIGWINCH signal
        begin
          @original_handler = trap('SIGWINCH') do
            Thread.current[:screen_size_dirty] = true
          end
        rescue ArgumentError
          # no-op signwinch is not supported
        end

        if Twenty48::OS.win?
          # enable win console support for Console Virtual Terminal Sequences
          require_relative '../win_api.rb'
          @win_api = Twenty48::WinApi.new
          @win_api.enable_virtual_terminal_processing
        end
        @output.print(ENABLE_ALTERNATE_BUFFER)
        @output.print(DISABLE_LINE_WRAP)
      end

      def initialize_screen
        @width = TTY::Screen.width
        @height = TTY::Screen.height
        @new_buffer = Array.new(height) { Array.new(width) }
        @old_buffer = Array.new(height) { Array.new(width) }
      end

      def width
        # leave a space for the new line character otherwise text will overflow on windows consoles
        @width - 1
      end

      # @param [DisplayInterface]
      def callback_listener=(interface)
        @call_back_listener = interface
      end

      attr_reader :height

      # @param [Integer] x_offset column
      # @param [Integer] y_offset row
      # @param [String] value can be a multi line string
      def set_value(x_offset, y_offset, value)
        return unless value

        value.to_s.split("\n").each_with_index do |line, y_index|
          # clamp string to be within window dimensions to prevent overflow
          clamped_line = line.slice(0, [line.size, width - x_offset].min).to_s
          clamped_line.each_char.with_index do |char, index|
            raise if index + x_offset >= width

            line = @new_buffer[y_index + y_offset]
            line[(x_offset + index)] = char
          end
        end
      end

      # @param [Integer] x column
      # @param [Integer] y row
      # set the position of the cursor
      def set_pos(x, y)
        @output.print(TTY::Cursor.move_to(x, y))
      end

      def set_prompt_area(x, y, width)
        @editor.set_prompt_area(x, y, width)
      end

      def erase
        @new_buffer.each(&:clear)
      end

      # reduces stuttering while typing by only refreshing the changed cells on the display
      # moving the display cursor and printing to terminal is an expensive operation.
      # This avoids us having to print out the whole screen when only a single character may have changed
      def efficient_refresh
        @refreshes ||= 0
        @refreshes += 1

        changes = 0

        @new_buffer.each_with_index do |line, row_index|
          @output.print(TTY::Cursor.move_to(0, row_index))
          cursor_index = 0
          line.each_with_index do |char, col_index|
            next if char == @old_buffer[row_index][col_index]

            changes += 1
            return false if changes > 5

            cursor_del = col_index - cursor_index
            if cursor_del > 0
              @output.print(TTY::Cursor.move(cursor_del, 0))
            end
            @output.print(char || ' ') # treat nil as empty space
            cursor_index = col_index + 1
          end
        end
        true
      end

      def refresh
        @output.print(TTY::Cursor.save)

        unless efficient_refresh
          @output.print(TTY::Cursor.move_to(0, 0))
          @output.print(TTY::Cursor.clear_screen)
          display_string = @new_buffer.map do |line|
            line.map { |char| char || ' ' }.join('')
          end.join($/)

          @output.print(display_string)
        end

        @output.flush
        @output.print(TTY::Cursor.restore)

        # clear old buffer and re-use as the new display buffer
        recycled_buffer = @old_buffer
        recycled_buffer.each(&:clear)
        @old_buffer = @new_buffer
        @new_buffer = recycled_buffer
      end

      def close
        trap('SIGWINCH', @original_handler) if @original_handler

        @output.print(DISABLE_ALTERNATE_BUFFER)
        @win_api&.restore
      end

      def process_input_stream
        if Thread.current[:screen_size_dirty]
          Thread.current[:screen_size_dirty] = false
          initialize_screen
          @call_back_listener.screen_resized
        end

        char = getch
        case char
        when *ENTER
          # next if @scroll_mode
          @call_back_listener.process_string(@editor.pop_input)
        when *LEFT
          @editor.append '←'
        when *RIGHT
          @editor.append '→'
        when *DOWN
          @editor.append '↓'
        when *UP
          @editor.append '↑'
        when *BACKSPACE
          @editor.backspace
        when /[ -~]/ # matches all printable ascii characters
          @editor.append(char) unless @editor.size > 0
        when nil
          # nil is returned when input stream EOF has been reached
          return false
        else
          # noop
        end
        true
      end

      private

      def getch
        @reader.read_keypress(echo: false, raw: true)
      end
    end
  end
end
