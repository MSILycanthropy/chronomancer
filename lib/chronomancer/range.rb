# frozen_string_literal: true

module Chronomancer
  class Range
    include Enumerable

    attr_reader :first, :last, :interval
    attr_accessor :exceptions

    def initialize(first, last = nil, interval = 1.month)
      @first = first&.to_time
      @last = last&.to_time
      @interval = interval
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

    def next_occurrence(from = Time.current)
      from = from.to_time

      return if from >= last
      return first if from < first

      diff = from - first
      intervals_passed = (diff / interval).ceil
      result = first + (intervals_passed * interval)

      return result if result <= last

      nil
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
      time.advance(split_duration(interval))
    end

    def split_duration(duration)
      [:years, :months, :weeks, :days, :hours, :minutes, :seconds].each_with_object({}) do |unit, parts|
        parts[unit] = duration.parts[unit] if duration.parts[unit]
      end
    end
  end
end
