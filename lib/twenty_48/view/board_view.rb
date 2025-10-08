# frozen_string_literal: true

module Twenty48
  module View
    class BoardView
      attr_accessor :x_pos, :y_pos, :canvas, :cell_height, :cell_width, :internal_width, :internal_height

      def initialize(canvas, x, y, width, height)
        self.canvas = canvas

        width_less_view_padding = width - (BORDER_AND_PADDING * 2)
        internal_x_boarder_count = BOARD_CELL_X_COUNT - 1
        self.cell_width = (width_less_view_padding - internal_x_boarder_count) / BOARD_CELL_X_COUNT
        combined_internal_width_of_cells = cell_width * BOARD_CELL_X_COUNT
        additional_x_padding = (width_less_view_padding - combined_internal_width_of_cells - internal_x_boarder_count) / 2
        self.internal_width = combined_internal_width_of_cells + internal_x_boarder_count
        self.x_pos = x + BORDER_AND_PADDING + additional_x_padding

        height_less_view_padding = height - (BORDER_AND_PADDING * 2)
        internal_y_boarder_count = BOARD_CELL_Y_COUNT - 1
        self.cell_height = (height_less_view_padding - internal_y_boarder_count) / BOARD_CELL_Y_COUNT
        combined_internal_height_of_cells = cell_height * BOARD_CELL_Y_COUNT
        additional_y_padding = (height_less_view_padding - combined_internal_height_of_cells - internal_y_boarder_count) / 2
        self.internal_height = combined_internal_height_of_cells + internal_y_boarder_count
        self.y_pos = y + BORDER_AND_PADDING + additional_y_padding
      end

      def render(game_state)
        print_boarders
        print_game game_state
      end

      private

      def print_boarders
        (BOARD_CELL_Y_COUNT - 1).times do |i|
          y = y_pos + cell_height + i + (i * cell_height)

          Draw::Line.print(canvas, x_pos, y, x_pos + internal_width - 1, y, char: '─')
        end

        (BOARD_CELL_X_COUNT - 1).times do |i|
          x = x_pos + cell_width + i + (i * cell_width)
          Draw::Line.print(canvas, x, y_pos, x, y_pos + internal_height - 1, char: '│')
        end
      end

      def print_game(game_state)
        game_state.each_with_index do |value, index|
          row = index / BOARD_CELL_X_COUNT
          column = index % BOARD_CELL_X_COUNT
          value_string = value&.to_s
          next unless value_string

          value_string_length = value_string.length

          number_of_x_borders = column
          x_padding = (cell_width - value_string_length) / 2
          x = x_pos + (column * cell_width) + number_of_x_borders + x_padding

          number_of_y_borders = row
          y_padding = (cell_height / 2)
          y = y_pos + (row * cell_height) + number_of_y_borders + y_padding

          Draw::PaintText.print(canvas, x, y, value_string)
        end
      end
    end
  end
end
