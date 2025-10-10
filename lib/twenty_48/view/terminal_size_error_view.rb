# frozen_string_literal: true

module Twenty48
  module View
    class TerminalSizeErrorView
      TEXT = "Your terminal size %{display_width}x%{display_height} is smaller than the minimum required" \
        " %{required_width}x%{required_height}.\n\n\nPlease resize your terminal"

      attr_accessor :canvas, :required_width, :required_height

      def initialize(canvas)
        self.canvas = canvas
      end

      def set_required_size(required_width, required_height)
        self.required_width = required_width
        self.required_height = required_height
      end

      def render(display_width, display_height)
        text = format(TEXT, display_width: display_width, display_height: display_height,
                      required_width: required_width, required_height: required_height)
        Draw::PaintText.print(canvas, 0, 0, text)
      end
    end
  end
end
