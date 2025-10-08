# frozen_string_literal: true

module Twenty48
  module View
    class PromptView
      attr_accessor :canvas, :history, :prompt_x, :prompt_y, :prompt_width

      DISPLAYED_HISTORY_COUNT = 4
      # maximum height of displayed text in this view
      MAX_HEIGHT = (APP_USAGE.lines + PROMPT.lines).size + DISPLAYED_HISTORY_COUNT
      INTERNAL_PADDING = 2

      def initialize(canvas)
        self.canvas = canvas
        self.history = []
      end

      def add_history(result)
        history << result
      end

      # @return The area of canvas that should be used for user input
      def prompt_area
        [prompt_x, prompt_y, prompt_width]
      end

      def render
        bottom = canvas.height - BORDER_AND_PADDING - 1
        right = canvas.width - BORDER_AND_PADDING - INTERNAL_PADDING - 1
        left = BORDER_AND_PADDING + INTERNAL_PADDING

        if history.empty? || history.last.success
          history_text = history.last(DISPLAYED_HISTORY_COUNT).map do |result|
            text = (' ' * PROMPT.length) + result.formatted_message
            # clamp text to be within the width of this view
            text.slice(0, (right - left - (INTERNAL_PADDING * 2)))
          end
          prompt_text = history_text.append(PROMPT).join($/)
        else
          # special text when last command was an error
          prompt_text = "#{history.last.formatted_message}\n\n#{APP_USAGE}#{PROMPT}"
        end

        top = bottom - prompt_text.lines.size - (INTERNAL_PADDING * 2)

        # y coordinate start of prompt input. starts at the row of the last line of prompt text
        self.prompt_y = top + INTERNAL_PADDING + prompt_text.lines.size - 1
        # x coordinate start of prompt input area
        self.prompt_x = left + INTERNAL_PADDING + PROMPT.length
        self.prompt_width = right - prompt_x - 1

        # Clear the canvas
        Draw::SolidRectangle.print(canvas, left, top, right, bottom, char: ' ')

        Draw::Border.print(canvas, left, top, right, bottom, style: :light)

        Draw::PaintText.print(canvas, left + INTERNAL_PADDING, top + INTERNAL_PADDING, prompt_text)
      end
    end
  end
end
