# frozen_string_literal: true

require_relative 'controller'
require 'concurrent-ruby'

module Twenty48
  class App
    attr_accessor :display, :controller, :canvas,
                  :terminal_size_error_view, :prompt_view, :app_chrome_view, :board_view, :editor_view,
                  :hint_loading_view,
                  :user_input_buffer, :invalidated_lock, :invalidated

    def self.run(display)
      new(display).run
    end

    def initialize(display)
      self.display = display
      display.callback_listener = self
      self.controller = Controller.new self

      self.canvas = Canvas.new DISPLAY_WIDTH, DISPLAY_HEIGHT

      self.prompt_view = View::PromptView.new canvas
      self.app_chrome_view = View::AppChromeView.new canvas
      self.board_view = View::BoardView.new canvas, BORDER_AND_PADDING, BORDER_AND_PADDING,
                                        (canvas.width - (BORDER_AND_PADDING * 2)),
                                        (canvas.height - BORDER_AND_PADDING - View::PromptView::MAX_HEIGHT)
      self.hint_loading_view = View::HintLoadingView.new canvas, (BORDER_AND_PADDING * 2), (BORDER_AND_PADDING * 2),
                                                         (canvas.width - (BORDER_AND_PADDING * 2) - 1),
                                                         (canvas.height - (BORDER_AND_PADDING * 2))
      self.editor_view = View::EditorView.new canvas

      self.user_input_buffer = Concurrent::Array.new
      self.invalidated = Concurrent::AtomicBoolean.new true
      self.invalidated_lock = Concurrent::ReentrantReadWriteLock.new
    end

    def schedule(user_input)
      user_input_buffer << user_input
    end

    def invalidate
      set_invalidated true
    end


    # Runs game loop blocking, until stdin reaches EOF; or an interrupt is received
    def run
      display.process_input_stream

      loop do
        Thread::pass

        process_user_input

        if invalidated?
          render_views
          set_invalidated false
        end

        break if @exiting
      end
    rescue Interrupt
      # no op. App will close
    ensure
      display.close
    end

    private

    def process_user_input
      while user_input = user_input_buffer.pop
        result = controller.process(user_input)
        if result
          prompt_view.add_history(result)
          @exiting ||= result.exiting?
        end
        set_invalidated true
      end
    end

    def set_invalidated(value)
      invalidated_lock.with_write_lock { invalidated.value = value }
    end

    def invalidated?
      invalidated_lock.with_read_lock { invalidated.value }
    end

    def render_views
      display.erase
      canvas.erase

      cursor_coordinates = nil

      if display.width <= DISPLAY_WIDTH || display.height <= DISPLAY_HEIGHT
        self.terminal_size_error_view ||= View::TerminalSizeErrorView.new canvas

        terminal_size_error_view.set_required_size(DISPLAY_WIDTH, DISPLAY_HEIGHT)
        terminal_size_error_view.render display.width, display.height
      else
        app_chrome_view.render controller.status
        board_view.render(controller.board_state)
        prompt_view.render
        cursor_coordinates = editor_view.render(display.editor, *prompt_view.prompt_area)
      end

      if controller.show_hint?
        self.hint_loading_view.render controller.hint
      end

      display.set_value(0, 0, canvas.to_s)
      display.refresh
      display.set_pos(*cursor_coordinates) if cursor_coordinates
    end

    def max_dimension(width1, height1, width2, height2)
      [[width1, width2].max, [height1, height2].max]
    end
  end
end
