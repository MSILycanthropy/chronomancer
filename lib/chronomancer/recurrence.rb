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

      (0..).lazy
        .map { |i| self[i] }
        .take(n)
        .to_a
    end

    def last(n = 1)
      raise Chronomancer::Error, "cannot get the last element of an infinite range" if infinite?

      raise ArgumentError, "negative array size" if n.negative?

      return [] if n.zero?
      return self[occurrences - 1] if n == 1

      (occurrences - 1).downto(0)
        .lazy
        .map { |i| self[i] }
        .take(n)
        .to_a.reverse
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
  end
end
