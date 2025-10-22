module Twenty48
  module View
    class HintLoadingView
      HEADER = "Thinking... (press Esc to dismiss)"
      PADDING = 2

      attr_accessor :canvas, :width, :height, :x_pos, :y_pos

      def initialize(canvas, x, y, width, height)
        self.canvas = canvas
        self.x_pos = x
        self.y_pos = y

        self.width = width
        self.height = height
      end

      def render(hint)
        # opaque background
        Draw::SolidRectangle.print(canvas, x_pos, y_pos, width, height, char: ' ')

        # print border
        Draw::Border.print(canvas, x_pos, y_pos, width, height, style: :ascii)

        # print header text
        header_width = HEADER.size
        start_x = (width - header_width) / 2
        Draw::PaintText.print(canvas, start_x, y_pos, HEADER)

        text_left = x_pos + PADDING
        text_top = y_pos + PADDING

        max_height = height - (PADDING * 2)
        max_width = width - (PADDING * 2) - 2

        formatted_hint = Utils::String.wrap(hint.to_s, max_width)
        truncated_hint = formatted_hint.lines.last(max_height).join

        Draw::PaintText.print(canvas, text_left, text_top, truncated_hint)
      end
    end
  end
end
