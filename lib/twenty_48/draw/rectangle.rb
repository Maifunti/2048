# frozen_string_literal: true

module Twenty48::Draw
  class Rectangle
    extend Twenty48::Draw

    def self.print(canvas, x1, y1, x2, y2, char: Twenty48::DRAW_CHAR)
      raise(ArgumentError, 'Canvas must be non null') unless canvas
      assert_is_char(char)
      assert_integer(x1, y1, x2, y2)
      assert_positive(x1, y1, x2, y2)

      # left
      Line.print(canvas, x1, y1, x1, y2, char: char)
      # top
      Line.print(canvas, x1, y1, x2, y1, char: char)
      # right
      Line.print(canvas, x2, y2, x2, y1, char: char)
      # bottom
      Line.print(canvas, x2, y2, x1, y2, char: char)
    end
  end
end
