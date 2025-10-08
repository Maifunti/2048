# frozen_string_literal: true

module Test
  module Helper
    def print_canvas(canvas)
      (0...canvas.height).map do |y|
        canvas.get_line(y).map do |value|
          value || ' '
        end.join('')
      end.join($/)
    end
  end
end
