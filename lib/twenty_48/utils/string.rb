module Twenty48
  module Utils::String
    extend self

    def wrap(input_string, width)
      raise 'width must be greater than 2' if width <= 2

      input_string.split(/(?<=\n)/).map do |line|
        limit line, width
      end.join
    end

    private

    def limit(input_string, width)
      result = String.new('')
      chomped_string = input_string
      a, b = [chomped_string[0...width], chomped_string[width..-1]]
      if b.nil? || b.chomp.empty?
        result << input_string
      else
        result << a + "-\n"
        result << limit(b.prepend('-'), width)
      end
      result
    end
  end
end
