# frozen_string_literal: true

module Twenty48
  module View
    class EditorView
      attr_reader :canvas

      def initialize(canvas)
        @canvas = canvas
      end

      def render(editor, x, y, width)
        editor_pos_x = x
        editor_pos_y = y
        editor_width = width

        editor_string = editor.to_s
        editor_cursor = editor.cursor_index

        # clamp editor cursor position to width of editor string
        editor_cursor = editor_string.size if editor_cursor > editor_string.size

        # clamp editor cursor position to width of editor box
        editor_cursor = 0 if editor_cursor < 0

        # clamp editor cursor position to width of editor box
        editor_cursor = editor_width - 1 if editor_cursor >= editor_width

        # clamp editor string
        editor_string.slice!(editor_width, editor_string.size) if editor_string.size >= editor_width

        padding = editor_width - editor_string.size
        output = editor_string + (' ' * padding)

        Draw::PaintText.print canvas, editor_pos_x, editor_pos_y, output

        cursor_coordinates = [editor_pos_x + editor_cursor, editor_pos_y]
        return cursor_coordinates
      end
    end
  end
end
