# frozen_string_literal: true

module Twenty48
  module View
    class AppChromeView
      HEADER = " 2048 #{Twenty48::VERSION} "
      VICTORY_MESSAGE = " YOU WON! "
      DEFEAT_MESSAGE = " GAME OVER "
      
      attr_accessor :canvas

      def initialize(canvas)
        self.canvas = canvas
      end
      
      def render(status)
        top = left = 0
        width = canvas.width
        height = canvas.height

        # print border
        Draw::Border.print(canvas, left, top, (width - 1), (height - 1), style: :thick)

        # print header text
        header_width = HEADER.size
        start_x = (width - header_width) / 2
        Draw::PaintText.print(canvas, start_x, 0, HEADER)

        if status == Twenty48::Controller::VICTORY
          header_width = VICTORY_MESSAGE.size
          start_x = (width - header_width) / 2
          start_y = canvas.height - 1
          Draw::PaintText.print(canvas, start_x, start_y, VICTORY_MESSAGE)
        elsif status == Twenty48::Controller::DEFEAT
          header_width = DEFEAT_MESSAGE.size
          start_x = (width - header_width) / 2
          start_y = canvas.height - 1
          Draw::PaintText.print(canvas, start_x, start_y, DEFEAT_MESSAGE)
        end
      end
    end
  end
end
