# frozen_string_literal: true

module Twenty48::Draw
  class Border
    extend Twenty48::Draw

    RIGHT_TOP_CORNER = 0
    RIGHT_BOTTOM_CORNER = 1
    LEFT_TOP_CORNER = 2
    LEFT_BOTTOM_CORNER = 3
    HORIZONTAL = 4
    VERTICAL = 5

    STYLE = { ascii: %w(+ + + + - |).freeze,
              light: %w(┐ ┘ ┌ └ ─ │).freeze,
              thick: %w(╗ ╝ ╔ ╚ ═ ║).freeze }

    # @param [Canvas] canvas
    # @param [Integer] top
    # @param [Integer] left
    # @param [Integer] width
    # @param [Integer] height
    # @param [Symbol] style. One of :ascii, :light, :thick
    def self.print(canvas, x1, y1, x2, y2, style: :ascii)
      raise(ArgumentError, 'Canvas must be non null') unless canvas
      assert_integer(x1, y1, x2, y2)
      assert_positive(x1, y1, x2, y2)
      raise(ArgumentError, 'style must be non null') unless style
      raise(ArgumentError, 'Invalid Style') unless STYLE.key?(style)

      resolved_style = STYLE[style]
      # left & right
      Line.print(canvas, x1, y1, x1, y2, char: resolved_style[VERTICAL])
      Line.print(canvas, x2, y1, x2, y2, char: resolved_style[VERTICAL])

      # top & bottom
      Line.print(canvas, x1, y1, x2, y1, char: resolved_style[HORIZONTAL])
      Line.print(canvas, x1, y2, x2, y2, char: resolved_style[HORIZONTAL])

      # corners
      Line.print(canvas, x1, y1, x1, y1, char: resolved_style[LEFT_TOP_CORNER])
      Line.print(canvas, x1, y2, x1, y2, char: resolved_style[LEFT_BOTTOM_CORNER])
      Line.print(canvas, x2, y1, x2, y1, char: resolved_style[RIGHT_TOP_CORNER])
      Line.print(canvas, x2, y2, x2, y2, char: resolved_style[RIGHT_BOTTOM_CORNER])
    end
  end
end
