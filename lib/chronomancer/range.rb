# frozen_string_literal: true

module Chronomancer
  class Range
    include Enumerable

    DEFAULT_OPTIONS = {
      interval_type: :months,
      interval_value: 1,
    }.freeze

    attr_reader :first, :last, :options

    attr_accessor :exceptions

    def initialize(first, last = nil, options = Hash.new { |_, k| DEFAULT_OPTIONS[k] })
      @first = first
      @last = last
      @options = options
    end

    def with_exceptions(ranges)
      previous = exceptions
      self.exceptions = ranges

      yield self

      self.exceptions = previous
    end

    def each
      return enum_for(:each) unless block_given?

      current = first

      while current <= last
        yield current unless excluded?(current)

        current = advance(current)
      end
    end

    def cover?(value)
      value >= first && value <= last
    end

    def excluded?(value)
      return false if exceptions.blank?

      exceptions.any? { |e| e.cover?(value) }
    end

    private

    def advance(time)
      time.advance(interval_type => interval_value)
    end
  end
end
