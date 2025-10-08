# frozen_string_literal: true

# allows us to provide input and capture stdout when using curses library
module Test
  class TTYDisplayAdapter < Twenty48::Display::TTYDisplayAdapter
    def self.build(width, height, stdin, stdout)
      new(width, height, stdin, stdout)
    end

    def initialize(width, height, stdin, stdout)
      set_test_display_dimensions(width, height)
      super(stdin, stdout)
    end

    # @overide
    def width
      @test_display_width
    end

    # @overide
    def height
      @test_display_height
    end

    ############### test methods

    def get_captured_output
      @old_buffer.map do |line|
        line.map { |char| char || ' ' }.join('')
      end.join($/)
    end

    def set_test_display_dimensions(width, height)
      @test_display_width = width
      @test_display_height = height
    end
  end
end
