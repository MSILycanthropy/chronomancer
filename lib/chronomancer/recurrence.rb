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
      return @start if n == 1

      take(n)
    end

    def last(n = 1)
      raise Chronomancer::Error, "cannot get the last element of an infinite range" if infinite?

      raise ArgumentError, "negative array size" if n.negative?

      return [] if n.zero?
      return @start + (interval * (occurrences - 1)) if n == 1

      n = [n, occurrences].min

      ((occurrences - n)...occurrences).map { |i| self[i] }
    end

    def [](n)
      raise ArgumentError, "negative array size" if n.negative?

      return if finite? && n > occurrences

      first + n * interval
    end

    def with_exceptions(ranges)
      previous = exceptions
      self.exceptions = ranges

      yield self

      self.exceptions = previous
    end

    def each
      return enum_for(:each) unless block_given?

      (0...occurrences).each { |n| yield self[n] }
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
      result = self[intervals_passed]

      return if result.nil?
      return result + interval if from == result
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

      diff = value - first
      intervals = (diff / interval).ceil

      return false if finite? && intervals > occurrences

      value == self[intervals] && !excluded?(value)
    end

    def excluded?(value)
      return false if exceptions.nil? || exceptions.empty?

      exceptions.any? { |e| e.include?(value) }
    end
  end
end
