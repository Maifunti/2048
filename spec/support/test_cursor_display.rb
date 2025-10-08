# frozen_string_literal: true

# allows us to provide input and capture stdout when using curses library
module Test
  class CursesDisplay < Twenty48::Display::CursesDisplayAdapter
    def self.build(width, height)
      new(width, height)
    end

    def initialize(width, height)
      set_test_display_dimensions(width, height)
      super()
    end

    # @overide
    def width
      @test_display_width
    end

    # @overide
    def height
      @test_display_height
    end

    # @overide
    def getch
      test_input_io.readchar
    rescue EOFError
      nil
    end

    ############### test methods

    def get_captured_output
      @display_buffer.map do |line|
        line.map { |char| char || ' ' }.join('')
      end.join($/)
    end

    def test_input_io
      @test_input_io ||= StringIO.new
    end

    def set_test_display_dimensions(width, height)
      @test_display_width = width
      @test_display_height = height
    end
  end
end
