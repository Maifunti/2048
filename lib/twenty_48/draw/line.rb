# frozen_string_literal: true

module Twenty48::Draw
  class Line
    extend Twenty48::Draw

    class << self
      # assumes the 2 points represent a vertical or horizontal line
      # assumes the 2 points cannot have negative coordinates
      # Points outside the canvas will be ignored
      def print(canvas, x1, y1, x2, y2, char: Twenty48::DRAW_CHAR)
        raise(ArgumentError, 'Canvas must be non null') unless canvas
        assert_is_char(char)
        assert_integer(x1, y1, x2, y2)
        assert_positive(x1, y1, x2, y2)

        if x1 != x2 && y1 == y2
          ###
          # horizontal line
          ###

          # prevent drawing outside the canvas
          x1 = [x1, (canvas.width - 1)].min
          x2 = [x2, (canvas.width - 1)].min

          min_x, max_x = *[x1, x2].sort!
          (min_x..max_x).each do |x|
            canvas.set_value(x, y1, char)
          end
        elsif y1 != y2 && x1 == x2
          ###
          # vertical line
          ###

          # prevent drawing outside the canvas
          y1 = [y1, (canvas.height - 1)].min
          y2 = [y2, (canvas.height - 1)].min

          min_y, max_y = *[y1, y2].sort!
          (min_y..max_y).each do |y|
            canvas.set_value(x1, y, char)
          end
        elsif y1 == y2 && x1 == x2
          # point
          canvas.set_value(x1, y1, char)
        else
          raise(ArgumentError, 'Only Straight lines are supported')
        end
      end
    end
  end
end
