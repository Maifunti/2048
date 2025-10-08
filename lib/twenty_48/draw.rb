# frozen_string_literal: true

module Twenty48::Draw
  def assert_positive(*args)
    raise(ArgumentError, 'Integer must be positive') if args.nil? || args.any?(&:negative?)
  end

  def assert_integer(*args)
    raise(ArgumentError, 'Coordinate must be an integer') unless args.nil? || args.all? { |i| i.is_a?(Integer) }
  end

  def assert_is_char(value)
    raise(ArgumentError, 'invalid char') unless value.is_a?(String) && value.length == 1
  end
end
