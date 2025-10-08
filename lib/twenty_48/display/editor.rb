# frozen_string_literal: true

module Twenty48
  module Display
    class Editor
      attr_writer :window

      def initialize(display)
        @display = display
        @editor_string = String.new
        @editor_cursor = 0
      end

      def set_prompt_area(x, y, length)
        @editor_pos_x = x
        @editor_pos_y = y
        @editor_width = length

        #  clamp editor cursor position to width of editor string
        @editor_cursor = @editor_string.size if @editor_cursor > @editor_string.size

        #  clamp editor cursor position to width of editor box
        @editor_cursor = 0 if @editor_cursor < 0

        #  clamp editor cursor position to width of editor box
        @editor_cursor = @editor_width - 1 if @editor_cursor >= @editor_width

        #  clamp editor string
        @editor_string.slice!(@editor_width, @editor_string.size) if @editor_string.size >= @editor_width

        padding = @editor_width - @editor_string.size
        output = @editor_string + (' ' * padding)
        @display.set_value(@editor_pos_x, @editor_pos_y, output)
        @display.set_pos(@editor_pos_x + @editor_cursor, @editor_pos_y)
      end

      def pop_input
        @editor_cursor = 0
        result = @editor_string.dup
        @editor_string.clear
        result
      end

      def backspace
        @editor_string.slice!(@editor_cursor - 1)
        @editor_cursor -= 1
      end

      def append(char)
        @editor_string << char
        @editor_cursor += 1
      end

      def move(by)
        @editor_cursor += by
      end

      def size
        @editor_string.size
      end
    end
  end
end
