# frozen_string_literal: true

module Twenty48
  class Canvas
    attr_accessor :width, :height, :data

    def initialize(width, height)
      self.width = width
      self.height = height
      self.data = Array.new(height) { Array.new(width) }
    end

    def get_line(y)
      data[y]
    end

    def get_value(x, y)
      raise 'value is outside canvas' if outside?(x, y)

      data[y][x]
    end

    def set_value(x, y, char)
      raise 'char length is greater than 1' if char.length > 1

      data[y][x] = char
    end

    def inside?(x, y)
      (0...width).cover?(x) && (0...height).cover?(y)
    end

    def outside?(x, y)
      !inside?(x, y)
    end

    def erase
      data.each &:clear
    end

    def to_s
      data.map { |row| row.map { |cell| cell || ' ' }.join }.join "\n"
    end
  end
end
