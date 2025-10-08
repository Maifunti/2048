# frozen_string_literal: true

require_relative 'controller'

module Twenty48
  class App
    attr_accessor :terminal_size_error_view, :display, :controller, :canvas, :prompt_view, :app_chrome_view, :board_view

    def self.run(display)
      new(display).run
    end

    def initialize(display)
      self.display = display
      display.callback_listener = self
      self.controller = Controller.new ai_engine: AiEngine

      self.canvas = Canvas.new DISPLAY_WIDTH, DISPLAY_HEIGHT
      self.prompt_view = View::PromptView.new canvas
      self.app_chrome_view = View::AppChromeView.new canvas
      self.board_view = View::BoardView.new canvas, BORDER_AND_PADDING, BORDER_AND_PADDING,
                                        (canvas.width - (BORDER_AND_PADDING * 2)),
                                        (canvas.height - BORDER_AND_PADDING - View::PromptView::MAX_HEIGHT)
      self.terminal_size_error_view = View::TerminalSizeErrorView.new canvas
    end

    def screen_resized
      render_views
    end

    def process_string(user_input)
      result = controller.process(user_input)
      prompt_view.add_history(result)
      @exiting = result.exiting?
    end

    # Runs game loop blocking, until stdin reaches EOF; or an interrupt is received
    def run
      loop do
        render_views
        break if @exiting || !display.process_input_stream
      end
    rescue Interrupt
      # no op. App will close
    ensure
      display.close
    end

    def render_views
      display.erase
      canvas.erase

      if display.width <= DISPLAY_WIDTH || display.height <= DISPLAY_HEIGHT
        terminal_size_error_view.set_required_size(DISPLAY_WIDTH, DISPLAY_HEIGHT)
        terminal_size_error_view.render display.width, display.height
      else
        app_chrome_view.render controller.status
        board_view.render(controller.board_state)
        prompt_view.render
        display.set_value(0, 0, canvas.to_s)
        display.set_prompt_area(*prompt_view.prompt_area)
      end

      display.refresh
    end

    def max_dimension(width1, height1, width2, height2)
      [[width1, width2].max, [height1, height2].max]
    end
  end
end
