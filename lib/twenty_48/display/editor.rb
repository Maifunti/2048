# frozen_string_literal: true

module Twenty48
  module Display
    class Editor
      attr_reader :cursor_index

      def initialize
        @buffer = Concurrent::Array.new
        @cursor_index = 0
      end

      def pop_input
        @cursor_index = 0
        result = to_s
        @buffer.clear
        result
      end

      def backspace
        @buffer.slice!(@cursor_index - 1)
        @cursor_index -= 1
      end

      def append(char)
        @buffer << char
        @cursor_index += 1
      end

      def move(by)
        @cursor_index += by
      end

      def size
        @buffer.size
      end

      def to_s
        @buffer.join
      end
    end
  end
end
