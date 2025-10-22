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

      attr_accessor :callback_listener, :editor, :reentrant_lock, :input, :output, :original_handler, :win_api, :reader,
                    :width, :height, :input_stream_thread, :new_buffer, :old_buffer
      private :reentrant_lock, :reentrant_lock=, :input, :input=, :output, :output=,
              :original_handler, :original_handler=, :win_api, :win_api=,:input_stream_thread, :input_stream_thread=,
              :editor=, :callback_listener

      # Callers must call #close when finished
      def initialize(inp = $stdin, outp = $stdout)
        self.input = inp
        self.output = outp
        self.reentrant_lock = Concurrent::ReentrantReadWriteLock.new
        self.reader = TTY::Reader.new(input: input, output: output, interrupt: :exit, track_history: false)

        initialize_screen

        self.editor = Editor.new

        # try to trap terminal resizes. Only works on systems that support SIGWINCH signal
        begin
          self.original_handler = trap('SIGWINCH') do
            Thread.new do
              initialize_screen
              callback_listener.invalidate
            end
          end
        rescue ArgumentError
          # no-op signwinch is not supported
        end

        if Twenty48::OS.win?
          # enable win console support for Console Virtual Terminal Sequences
          require_relative '../win_api.rb'
          self.win_api = Twenty48::WinApi.new
          win_api.enable_virtual_terminal_processing
        end

        print(ENABLE_ALTERNATE_BUFFER)
        print(DISABLE_LINE_WRAP)
      end

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

            line = new_buffer[y_index + y_offset]
            line[(x_offset + index)] = char
          end
        end
      end

      # @param [Integer] x column
      # @param [Integer] y row
      # set the position of the cursor
      def set_pos(x, y)
        print(TTY::Cursor.move_to(x, y))
      end

      def erase
        new_buffer.each(&:clear)
      end

      def refresh
        print(TTY::Cursor.save)

        unless efficient_refresh
          print(TTY::Cursor.move_to(0, 0))
          print(TTY::Cursor.clear_screen)
          display_string = new_buffer.map do |line|
            line.map { |char| char || ' ' }.join('')
          end.join($/)

          print(display_string)
        end

        flush
        print(TTY::Cursor.restore)

        # clear old buffer and re-use as the new display buffer
        recycled_buffer = old_buffer
        recycled_buffer.each(&:clear)
        self.old_buffer = new_buffer
        self.new_buffer = recycled_buffer
      end

      def close
        trap('SIGWINCH', original_handler) if original_handler

        print(DISABLE_ALTERNATE_BUFFER)
        win_api&.restore

        input_stream_thread&.terminate
      end

      def process_input_stream
        self.input_stream_thread = Thread.new do
          loop do
            char = getch

            case char
            when *ENTER
              callback_listener.schedule_command(editor.pop_input)
            when *LEFT
              editor.append '←'
              callback_listener.schedule_command editor.pop_input if editor.size == 1
            when *RIGHT
              editor.append '→'
              callback_listener.schedule_command editor.pop_input if editor.size == 1
            when *DOWN
              editor.append '↓'
              callback_listener.schedule_command editor.pop_input if editor.size == 1
            when *UP
              editor.append '↑'
              callback_listener.schedule_command editor.pop_input if editor.size == 1
            when *BACKSPACE
              editor.backspace
            when /[ -~]/ # matches all printable ascii characters
              editor.append(char) unless editor.size > 0
            else
              next
            end

            callback_listener.invalidate

            true
          end
        end
      end

      private

      def initialize_screen
        self.width = TTY::Screen.width - 1 # leave a space for the new line character otherwise text will overflow on windows consoles
        self.height = TTY::Screen.height
        self.new_buffer = Array.new(height) { Array.new(width) }
        self.old_buffer = Array.new(height) { Array.new(width) }
      end

      # reduces stuttering while typing by only refreshing the changed cells on the display
      # moving the display cursor and printing to terminal is an expensive operation.
      # This avoids us having to print out the whole screen when only a single character may have changed
      def efficient_refresh
        changes = 0

        new_buffer.each_with_index do |line, row_index|
          print(TTY::Cursor.move_to(0, row_index))
          cursor_index = 0
          line.each_with_index do |char, col_index|
            next if char == old_buffer[row_index][col_index]

            changes += 1
            return false if changes > 5

            cursor_del = col_index - cursor_index
            if cursor_del > 0
              print(TTY::Cursor.move(cursor_del, 0))
            end
            print(char || ' ') # treat nil as empty space
            cursor_index = col_index + 1
          end
        end
        true
      end

      def getch
        char = nil
        loop do
          reentrant_lock.with_write_lock do
            char = reader.read_keypress(echo: false, raw: true, nonblock: true)
          end
          break if char

          Thread::pass
        end

        char
      end

      def print(object)
        reentrant_lock.with_write_lock  do
          output.print object
        end
      end

      def flush
        reentrant_lock.with_write_lock do
          output.flush
        end
      end
    end
  end
end
