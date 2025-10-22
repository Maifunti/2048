module Twenty48
  class AiEngine
    SYSTEM = "You are playing a game of 2048. The current board state is: [%s]"
    USER = "What is the optimal next move? Return only: UP, DOWN, LEFT, or RIGHT"

    attr_accessor :board_state, :callback, :client, :hint

    def self.fetch(board_state, callback, client = Client::KimiAi)
      instance = new(board_state, callback, client)
      instance.fetch
      instance
    end

    def initialize(board_state, callback, client)
      self.board_state = board_state
      self.callback = callback
      self.client = client
    end

    def fetch
      board_state_string = board_state.each_slice(Twenty48::BOARD_CELL_X_COUNT).map do |row|
        row.map { |cell| cell || "" }
      end.join("\n")
      system = SYSTEM % board_state_string
      self.hint = ''

      on_update = lambda do |updated_hint|
        return if @aborted

        self.hint = updated_hint
        callback.on_hint_fetch_update hint
      end

      on_error = lambda do |error|
        return if @aborted

        self.hint << "\n\nError fetching data\n\n"
        self.hint << error.inspect
        callback.on_hint_fetch_error hint
      end

      on_complete = lambda do
        return if @aborted

        callback.on_hint_fetch_complete hint
      end

      self.client = client.create system, USER, update: on_update, complete: on_complete, error: on_error
    rescue => e
      @aborted = true
      self.hint << "\n\nError fetching data\n\n"
      callback.on_hint_fetch_error(e)
    end

    def abort
      self.client&.close
      @aborted = true
      self.hint << "\n\n\nABORTED\n\n"
    end
  end
end