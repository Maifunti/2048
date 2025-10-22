# frozen_string_literal: true

module Twenty48
  class Controller
    TOTAL_CELL_COUNT = BOARD_CELL_X_COUNT * BOARD_CELL_Y_COUNT
    GENERATED_VALUES = [2, 4].freeze

    PLAYING = 'PLAYING'
    VICTORY = 'VICTORY'
    DEFEAT = 'DEFEAT'
    LOADING_HINT = 'LOADING_HINT'

    DEFAULT_HINT = 'No AI agent configured'

    class Result
      attr_accessor :command, :success, :message

      def initialize(command)
        self.command = command
      end

      def for_failure(message)
        self.success = false
        self.message = message
        self
      end

      def for_hint(message)
        self.success = true
        self.message = message
        self
      end

      def for_success
        self.success = true
        self
      end

      def formatted_message
        formmatted_input = command.strip
        if success
          [formmatted_input, message].join ' '
        else
          "'#{formmatted_input}' #{message}"
        end
      end

      def exiting?
        command == 'Q'
      end
    end

    attr_accessor :history, :board_state, :status, :disable_cell_generation, :ai_client_klass, :ai_engine, :listener, :hint

    def initialize(listener, initial_state: nil, ai_client_klass: Client::KimiAi, disable_cell_generation: false)
      total_cell_count = BOARD_CELL_X_COUNT * BOARD_CELL_Y_COUNT
      self.history = []
      self.disable_cell_generation = disable_cell_generation
      self.status = PLAYING
      self.listener = listener
      self.ai_client_klass = ai_client_klass

      if initial_state
        self.board_state = initial_state
      else
        self.board_state = Array.new(total_cell_count)
        new_board
      end

      detect_end_game
    end

    # @param [UserInput::Command|UserInput::Control] user_input
    # @return [Result]
    def process(user_input)
      if user_input.is_a? UserInput::Command
        process_command user_input
      elsif user_input.is_a? UserInput::Control
        process_control user_input
      else
        raise 'unknown user input class'
      end
    end

    def on_hint_fetch_update(updated_hint)
      self.hint = updated_hint
      listener.invalidate
    end

    def on_hint_fetch_complete(completed_hint)
      self.hint = completed_hint
      self.ai_engine = nil
      listener.invalidate
    end

    def on_hint_fetch_error(_error)
      ai_engine.abort
      self.ai_engine = nil
      listener.invalidate
    end

    def loading_hint?
      !!ai_engine
    end

    def show_hint?
      ai_engine || hint
    end

    private

    def process_control(user_input)
      case user_input.value
      when :escape
        if ai_engine
          ai_engine.abort
          self.ai_engine = nil
        elsif hint
          self.hint = nil
        end
      else
        #no-op
      end
    end

    def process_command(user_input)
      command = user_input.value.to_s.strip
      return Result.new(nil, nil).for_failure("Bad Input") unless command

      command = command.upcase
      result = Result.new(command)

      return if ai_engine # command cannot be processed while ai_engine is fetching

      case command
      when '↑'
        move { up }
      when '↓'
        move { down }
      when '←'
        move { left }
      when '→'
        move { right }
      when 'U'
        undo
      when 'N'
        new_board
      when 'H'
        self.ai_engine = AiEngine.fetch board_state, self
      when 'Q'
        # App will exit
      else
        return result.for_failure('Unknown command')
      end

      result.for_success
    end

    def move
      old_state = board_state.dup
      updated = yield
      if updated
        history.push old_state
        generate_new_cell
      end
      detect_end_game
    end

    def up
      updated = false

      # move from top of the board to the bottom, moving cells as required
      (0...BOARD_CELL_Y_COUNT).each_with_index do |current_row|
        (0...BOARD_CELL_X_COUNT).each_with_index do |current_column|
          cell_index = (current_row * BOARD_CELL_X_COUNT) + current_column

          if board_state[cell_index].nil?
            # search for first occupied cell in the same column and move it up to the vacant cell
            (current_row...BOARD_CELL_Y_COUNT).each_with_index do |candidate_row|
              candidate_cell_index = (candidate_row * BOARD_CELL_X_COUNT) + current_column
              if board_state[candidate_cell_index]
                board_state[cell_index] = board_state[candidate_cell_index]
                board_state[candidate_cell_index] = nil
                updated = true
                break
              end
            end
          end

          next unless board_state[cell_index]

          #  merge cells upwards
          (1...BOARD_CELL_Y_COUNT).each_with_index do |row_diff|
            candidate_cell_index = cell_index + (row_diff * BOARD_CELL_X_COUNT)
            break if candidate_cell_index >= TOTAL_CELL_COUNT

            if board_state[candidate_cell_index]
              if board_state[cell_index] == board_state[candidate_cell_index]
                board_state[cell_index] = board_state[candidate_cell_index] + board_state[cell_index]
                board_state[candidate_cell_index] = nil
                updated = true
              end

              break
            end
          end
        end
      end

      updated
    end

    def down
      updated = false

      # move from bottom of the board to the top, moving cells as required
      (BOARD_CELL_Y_COUNT - 1).downto(0).each_with_index do |current_row|
        (0...BOARD_CELL_X_COUNT).each_with_index do |current_column|
          cell_index = (current_row * BOARD_CELL_X_COUNT) + current_column

          if board_state[cell_index].nil?
            # search for first occupied cell in the same column and move it down to the vacant cell
            (current_row).downto(0).each_with_index do |candidate_row|
              candidate_cell_index = (candidate_row * BOARD_CELL_X_COUNT) + current_column
              if board_state[candidate_cell_index]
                board_state[cell_index] = board_state[candidate_cell_index]
                board_state[candidate_cell_index] = nil
                updated = true
                break
              end
            end
          end

          next unless board_state[cell_index]

          #  merge cells downwards
          (1...BOARD_CELL_Y_COUNT).each_with_index do |row_diff|
            candidate_cell_index = cell_index - (row_diff * BOARD_CELL_Y_COUNT)
            break if candidate_cell_index < 0

            if board_state[candidate_cell_index]
              if board_state[cell_index] == board_state[candidate_cell_index]
                board_state[cell_index] = board_state[candidate_cell_index] + board_state[cell_index]
                board_state[candidate_cell_index] = nil
                updated = true
              end

              break
            end
          end
        end
      end

      updated
    end

    def left
      updated = false

      # move from the left of the board to the right, moving cells as required
      (0...BOARD_CELL_Y_COUNT).each_with_index do |current_row|
        (0...BOARD_CELL_X_COUNT).each_with_index do |current_column|
          cell_index = (current_row * BOARD_CELL_X_COUNT) + current_column

          if board_state[cell_index].nil?
            # search for first occupied cell in the same column and move it up to the vacant cell
            (current_column...BOARD_CELL_X_COUNT).each_with_index do |candidate_column|
              candidate_cell_index = (current_row * BOARD_CELL_X_COUNT) + candidate_column
              if board_state[candidate_cell_index]
                board_state[cell_index] = board_state[candidate_cell_index]
                board_state[candidate_cell_index] = nil
                updated = true
                break
              end
            end
          end

          next unless board_state[cell_index]

          #  merge cells
          ((current_column + 1)...BOARD_CELL_X_COUNT).each_with_index do |candidate_column|
            candidate_cell_index = cell_index + (candidate_column - current_column)

            if board_state[candidate_cell_index]
              if board_state[cell_index] == board_state[candidate_cell_index]
                board_state[cell_index] = board_state[candidate_cell_index] + board_state[cell_index]
                board_state[candidate_cell_index] = nil
                updated = true
              end

              break
            end
          end
        end
      end

      updated
    end

    def right
      updated = false

      # move from the right of the board to the left, moving cells as required
      (0...BOARD_CELL_Y_COUNT).each_with_index do |current_row|
        (BOARD_CELL_X_COUNT - 1).downto(0).each_with_index do |current_column|
          cell_index = (current_row * BOARD_CELL_X_COUNT) + current_column

          if board_state[cell_index].nil?
            # search for first occupied cell in the same column and move it right to the vacant cell
            (current_column).downto(0).each_with_index do |candidate_column|
              candidate_cell_index = (current_row * BOARD_CELL_X_COUNT) + candidate_column
              if board_state[candidate_cell_index]
                board_state[cell_index] = board_state[candidate_cell_index]
                board_state[candidate_cell_index] = nil
                updated = true
                break
              end
            end
          end

          next unless board_state[cell_index]

          #  merge cells
          (1..current_column).each_with_index do |column_diff|
            candidate_cell_index = cell_index - column_diff

            if board_state[candidate_cell_index]
              if board_state[cell_index] == board_state[candidate_cell_index]
                board_state[cell_index] = board_state[candidate_cell_index] + board_state[cell_index]
                board_state[candidate_cell_index] = nil
                updated = true
              end

              break
            end
          end
        end
      end

      updated
    end

    def new_board
      board_state.clear

      initial_cell_count = rand(TOTAL_CELL_COUNT)
      cell_count = 0

      while cell_count <= initial_cell_count
        random_index = rand TOTAL_CELL_COUNT
        if board_state[random_index].nil?
          board_state[random_index] = 2
          cell_count += 1
        end
      end
    end

    def undo
      self.board_state = history.pop if history.length > 0
    end

    def generate_new_cell
      return if disable_cell_generation

      loop do
        random_index = rand TOTAL_CELL_COUNT
        if board_state[random_index].nil?
          new_value = GENERATED_VALUES.sample
          board_state[random_index] = new_value
          break
        end
      end
    end

    def detect_end_game
      win = board_state.find do |cell_value|
        cell_value && cell_value >=2048
      end

      if win
        self.status = VICTORY
        return
      end

      board_move_available = false

      cell_count = 0
      (0...TOTAL_CELL_COUNT).each_with_index do |index|
        cell_count += 1

        current_cell = board_state[index]

        if current_cell.nil?
          board_move_available = true
          break
        end # it's an empty cell, so a move is still available

        next_cell_horizontally = board_state[index + 1] if (index + 1) % BOARD_CELL_X_COUNT != 0 # nil if next cell is on a new row
        h_merge_available = current_cell == next_cell_horizontally

        next_cell_vertically = board_state[index + BOARD_CELL_X_COUNT]
        y_merge_available = current_cell == next_cell_vertically
        if h_merge_available || y_merge_available
          board_move_available = true
          break
        end
      end

      if board_move_available
        self.status = PLAYING
      else
        self.status = DEFEAT
      end
    end
  end
end
