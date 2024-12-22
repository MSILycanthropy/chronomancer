# frozen_string_literal: true

module Chronomancer
  class Range
    include Enumerable

    attr_reader :occurrences, :interval
    attr_accessor :exceptions

    def initialize(start, end_or_occurrences = nil, interval = 1.month)
      @start = start&.to_time
      @interval = interval

      @occurrences = case end_or_occurrences
      when Integer
        end_or_occurrences
      when Time, Date
        diff = end_or_occurrences.to_time - @start

        @occurrences = (diff / interval).ceil
      end
    end

    def first(n = 1)
      return @start if n == 1

      take(n)
    end

    def last(n = 1)
      raise Chronomancer::Error, "cannot get the last element of an infinite range" if infinite?

      raise ArgumentError, "negative array size" if n.negative?

      return [] if n.zero?
      return @start + (interval * (occurrences - 1)) if n == 1

      n = [n, occurrences].min

      ((occurrences - n)...occurrences).map { |i| nth(i) }
    end

    def nth(n)
      raise ArgumentError, "negative array size" if n.negative?

      return if n > occurrences

      current = first

      n.times { current = advance(current) }

      current
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

      if infinite?
        loop do
          yield current unless excluded?(current)

          current = advance(current)
        end
      else
        while current <= last
          yield current unless excluded?(current)

          current = advance(current)
        end
      end
    end

    def to_a
      raise Chronomancer::Error, "cannot convert infinite range to an array" if infinite?

      super
    end

    def next_occurrence(from = Time.current)
      from = from.to_time

      return if finite? && from >= last
      return first if from < first

      diff = from - first
      intervals_passed = (diff / interval).ceil
      result = first + (intervals_passed * interval)

      return result if infinite? || result <= last

      nil
    end

    def infinite?
      @occurrences.nil?
    end

    def finite?
      !infinite?
    end

    def include?(value)
      cover?(value) && !excluded?(value)
    end

    def cover?(value)
      end_check = infinite? || value <= last

      value >= first && end_check
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
