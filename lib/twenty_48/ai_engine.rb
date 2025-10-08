module Twenty48
  module AiEngine
    SYSTEM = "You are playing a game of 2048. The current board state is: [%s]"
    USER = "What is the optimal next move? Return only: UP, DOWN, LEFT, or RIGHT"

    extend self

    def generate_hint(board_state)
      board_state_string = board_state.each_slice(Twenty48::BOARD_CELL_X_COUNT).map &:to_s
      system = SYSTEM % board_state_string
      Client::KimiAi.create system, USER
    end
  end
end