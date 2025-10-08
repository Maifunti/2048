# frozen_string_literal: true

module Twenty48::Draw
  class SolidRectangle
    extend Twenty48::Draw

    def self.print(canvas, x1, y1, x2, y2, char: Twenty48::DRAW_CHAR)
      raise(ArgumentError, 'Canvas must be non null') unless canvas
      assert_is_char(char)
      assert_integer(x1, y1, x2, y2)
      assert_positive(x1, y1, x2, y2)

      miny, maxy = *[y1, y2].sort
      (miny..maxy).each do |y|
        Line.print(canvas, x1, y, x2, y, char: char)
      end
    end
  end
end
