# frozen_string_literal: true

module Chronomancer
  class Recurrence
    include Enumerable

    attr_accessor :occurrences, :interval, :exceptions

    def initialize(start, occurrences = nil, interval = 1.month)
      @start = start&.to_time
      @interval = interval

      @occurrences = occurrences
    end

    def first(n = 1)
      return [] if n.zero?
      return @start if n == 1

      (0..).lazy.map { |i| self[i] }.take(n).to_a
    end

    def last(n = 1)
      raise Chronomancer::Error, "cannot get the last element of an infinite range" if infinite?

      raise ArgumentError, "negative array size" if n.negative?

      return [] if n.zero?
      return self[occurrences - 1] if n == 1

      (occurrences - 1).downto(0).lazy.map { |i| self[i] }.take(n).to_a.reverse
    end

    def [](n)
      raise ArgumentError, "negative array size" if n.negative?

      return if finite? && n > occurrences

      result = first + n * interval

      return if exception?(result)

      result
    end

    def with_exceptions(ranges)
      previous = exceptions
      self.exceptions = ranges

      yield self

      self.exceptions = previous
    end

    def each(&block)
      return enum_for(:each) unless block_given?

      enum = (0..).lazy
        .map { |n| self[n] }
        .filter_map(&:itself)

      (infinite? ? enum : enum.take(occurrences)).each(&block)
    end

    def to_a
      raise Chronomancer::Error, "cannot convert infinite range to an array" if infinite?

      super
    end

    def next_occurrence(from = Time.current)
      from = from.to_time

      return if finite? && from >= last
      return first if from < first

      intervals = time_to_intervals(from)
      result = self[intervals + 1]

      return if result.nil?

      result += interval if from == result

      return if exception?(result)
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
      return false unless value.respond_to?(:to_time)

      value = value.to_time

      return false if value < first

      intervals = time_to_intervals(value)

      return false if finite? && intervals > occurrences

      value == self[intervals]
    end

    def exception?(value)
      return false if exceptions.nil? || exceptions.empty?

      exceptions.any? { |e| e.include?(value) }
    end

    def totally_covered_from?(recurrence, from = nil)
      return false if recurrence.interval > interval
      return false if infinite? && recurrence.finite?

      occurrence = from.nil? ? 0 : time_to_intervals(from) + 1

      return (occurrence..ocurrences).all? { |i| recurrence.include?(self[i]) } if finite?

      start = self[occurrence]

      puts recurrence.include?(start)

      recurrence.include?(start) && intervals_divide_evenly?(interval, recurrence.interval)
    end

    private

    def time_to_intervals(time)
      intervals = ((time - first) / interval).ceil

      result = intervals

      occurrence = first + (intervals * interval)

      result -= 1 if occurrence > time

      result
    end

    def intervals_divide_evenly?(i1, i2)
      return true if i1 == i2
      return intervals_divide_evenly?(i2, i1) if i2 > i1

      i1_seconds = interval_to_variable_seconds(i1)
      i2_seconds = interval_to_variable_seconds(i2)

      i1_seconds.product(i2_seconds).all? { |arr| arr.first % arr.last == 0 }
    end

    CONSTANT_PARTS = [:days, :minutes, :seconds].freeze
    def interval_to_variable_seconds(interval)
      parts = interval.parts
      constant_seconds = parts
        .select { |unit, _| CONSTANT_PARTS.include?(unit) }
        .sum { |unit, value| value.send(unit).in_seconds }

      return [constant_seconds] unless parts.key?(:months) || parts.key?(:years)

      possibilities = [constant_seconds]

      possibilities = expand_month_possibilities(possibilities, parts) if parts.key?(:months)
      possibilities = expand_year_possibilities(possibilities, parts) if parts.key?(:years)

      possibilities.uniq.sort
    end

    def expand_month_possibilities(possibilities, parts)
      [28, 29, 30, 31].flat_map do |days_in_month|
        month_seconds = days_in_month.days.in_seconds * parts[:months]
        possibilities.map { |base| base + month_seconds }
      end
    end

    def expand_year_possibilities(possibilities, parts)
      [365, 366].flat_map do |days_in_year|
        year_seconds = days_in_year.days.in_seconds * parts[:years]
        possibilities.map { |base| base + year_seconds }
      end
    end
  end
end
