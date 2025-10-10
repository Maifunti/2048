# frozen_string_literal: true

module Twenty48
  module Display
    # Uses curses gem (gnu ncurses) for interacting with the terminal
    # This display adapter is more performant than TTYDisplayAdapter. It requires
    # a native library gem extension which reduces it's portability
    class CursesDisplayAdapter
      require 'curses'
      require_relative 'editor.rb'

      # We're using both curses keypad codes and ascii ctrl characters
      BACKSPACE = [Curses::KEY_BACKSPACE, 8]
      ENTER = [Curses::KEY_ENTER, 13, 10, $/]
      LEFT = [Curses::KEY_LEFT]
      RIGHT = [Curses::KEY_RIGHT]
      DOWN = [Curses::KEY_DOWN]
      UP = [Curses::KEY_UP]

      attr_accessor :width, :height, :callback_listener, :editor, :main_window, :display_buffer, :input_stream_thread,
                    :input_stream_thread, :reentrant_lock

      private :callback_listener, :editor=, :main_window, :main_window=, :display_buffer, :display_buffer=,
              :input_stream_thread, :input_stream_thread, :reentrant_lock, :reentrant_lock=

      # Callers must call #close when finished
      def initialize
        Curses.init_screen
        Curses.cbreak
        Curses.noecho

        self.editor = Editor.new
        self.reentrant_lock = Concurrent::ReentrantReadWriteLock.new

        initialize_window
      end

      # @param [Integer] x column
      # @param [Integer] y row
      # @param [String] value can be a multi line string
      def set_value(x, y, value)
        return unless value
        return if y >= height

        reentrant_lock.with_write_lock do
          value.lines.each_with_index do |line, row_index|
            break if y + row_index > height
            next if line.empty?

            # puts y + row_index
            line_buffer = display_buffer[y + row_index]
            break unless line_buffer

            # clamp string to be within window dimensions to prevent overflow
            clamped_value = line.slice(0, [line.size, width - x].min)
            next if clamped_value.nil?

            clamped_value.each_char.with_index do |char, index|
              break if index + x > line_buffer.size

              line_buffer[(x + index)] = char
            end
          end
        end
      end

      # @param [Integer] x column
      # @param [Integer] y row
      def set_pos(x, y)
        reentrant_lock.with_write_lock do
          main_window.setpos(y, x)
          main_window.refresh
        end
      end

      def set_prompt_area(x, y, width)
        editor.set_prompt_area(x, y, width)
      end

      def erase
        reentrant_lock.with_write_lock do
          main_window.erase
          display_buffer.each(&:clear)
        end
      end

      def refresh
        reentrant_lock.with_write_lock do
          display_string = display_buffer.map do |line|
            line.map { |char| char || ' ' }.join('')
          end.join

          main_window.setpos(0, 0)
          main_window.addstr(display_string)
          main_window.refresh
        end
      end

      def close
        Curses.close_screen
        input_stream_thread&.terminate
      end

      def process_input_stream
        self.input_stream_thread = Thread.new do
          loop do
            code = getch

            case code
            when Curses::KEY_RESIZE
              initialize_window
            when *ENTER
              # next if @scroll_mode
              callback_listener.schedule_command(editor.pop_input)
            when /[ -~]/ # matches all printable ascii characters
              editor.append(code) unless editor.size > 0
            when *LEFT
              editor.append '←'
            when *RIGHT
              editor.append '→'
            when *DOWN
              editor.append '↓'
            when *UP
              editor.append '↑'
            when *BACKSPACE
              editor.backspace
            when nil
              # nil is returned when input stream EOF has been reached
            else
              # noop
            end

            callback_listener.invalidate

            true
          end
        end

      end

      private

      def initialize_window
        reentrant_lock.with_write_lock do
          main_window&.close
          Curses.refresh
          self.main_window = Curses::Window.new(0, 0, 0, 0)
          # use keypad mode so curses can convert control escape sequences to curses keypad codes
          main_window.keypad(true)
          main_window.timeout = 0
          self.width = main_window.maxx - 1 # leave a space for the new line character otherwise text will overflow on windows consoles
          self.height = main_window.maxy
          self.display_buffer = Array.new(height) { Array.new(width) }
        end
      end

      def getch
        char = nil
        loop do
          reentrant_lock.with_write_lock do
            char = main_window.getch
          end
          break if char

          Thread::pass
        end

        char
      rescue EOFError
        nil
      end
    end
  end
end
