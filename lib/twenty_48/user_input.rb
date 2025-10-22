module Twenty48
  class UserInput
    class Command
      attr_reader :value

      def initialize(value)
        @value = value
      end
    end

    class Control
      attr_reader :value

      def initialize(value)
        @value = value
      end
    end

    class << self
      def command(string)
        Command.new string
      end

      def control_sequence(symbol)
        Control.new symbol
      end
    end
  end
end