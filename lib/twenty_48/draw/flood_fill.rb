# frozen_string_literal: true

module Twenty48::Draw
  class FloodFill
    extend Twenty48::Draw

    def self.print(canvas, target_x, target_y, replacement_color)
      raise(ArgumentError, 'Canvas must be non null') unless canvas
      assert_integer(target_x, target_y)
      assert_positive(target_x, target_y)
      assert_is_char(replacement_color)

      return if canvas.outside?(target_x, target_y)

      target_color = canvas.get_value(target_x, target_y)
      return if target_color == replacement_color

      queue = []
      queue << [target_x, target_y]

      until queue.empty?
        starting_x, y = *queue.pop
        left_boundary = right_boundary = starting_x

        while canvas.inside?(left_boundary, y)
          break if canvas.get_value(left_boundary, y) != target_color
          left_boundary -= 1
        end
        while canvas.inside?(right_boundary, y)
          break if canvas.get_value(right_boundary, y) != target_color
          right_boundary += 1
        end

        ((left_boundary + 1)..(right_boundary - 1)).each do |x|
          # fill value
          canvas.set_value(x, y, replacement_color)

          # test upper row
          if canvas.inside?(x, y - 1)
            value = canvas.get_value(x, y - 1)
            queue << [x, y - 1] if value == target_color
          end
          # test lower row
          if canvas.inside?(x, y + 1)
            value = canvas.get_value(x, y + 1)
            queue << [x, y + 1] if value == target_color
          end
        end
      end
    end
  end
end
