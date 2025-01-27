# frozen_string_literal: true

module Chronomancer
  class Sequence
    include Enumerable

    class << self
      def respond_to_missing?(method_name)
        Builder.instance_methods.include?(method_name) || super
      end

      def method_missing(method_name, ...)
        if Builder.instance_methods.include?(method_name)
          Builder.new.send(method_name, ...)
        else
          super
        end
      end

      def dump(obj)
        return if obj.nil?
        return dump(load(obj)) if obj.is_a?(String)

        {
          active: obj.active.as_json,
          historical: obj.historical.map(&:as_json),
          exceptions: obj.exceptions.map(&:as_json),
        }.reject { |_, v| v.blank? }.to_json
      end

      def load(str)
        return if str.blank?

        json = JSON.parse(str)

        instance = new(Recurrence.from_json(json["active"]))
        instance.instance_variable_set(:@historical, json["historical"]&.map { |h| Recurrence.from_json(h) })
        instance.instance_variable_set(:@exceptions, json["exceptions"]&.map { |e| Recurrence.from_json(e) })

        instance
      end
    end

    attr_reader :active, :historical, :exceptions

    def initialize(initial)
      @active = ensure_recurrence(initial)
      @historical = []
      @exceptions = []
    end

    def each(&block)
      return enum_for(:each) unless block_given?

      recurrences = [*historical, active].sort_by(&:first)

      recurrences.each do |recurrence|
        recurrence.with_exceptions(exceptions) { |r| r.each(&block) }
      end
    end

    def pause(recurrence)
      exceptions << ensure_recurrence(recurrence)
    end

    def reconfigure(stop = nil, restart = nil, **changes)
      if stop.nil?
        reconfigure_active(**changes)
      else
        raise Chronomancer::Error, "reconfiguring around #{stop} would break the sequence, a sequence must " \
          "have non-overlapping recurrences" if stop <= active.first
        raise Chronomancer::Error, "stop must be between #{active.first} and #{active.last}, try specifying " \
          "a restart date if you would like to skip occurrences" if active.finite? && stop >= active.last

        restart ||= stop
        around = ((stop - active.first) / active.interval).ceil unless stop.nil?

        if around == current_active_occurrence
          reconfigure_active(**changes)
          return self
        end

        interval = changes[:interval] || active.interval
        occurrences = if changes.key?(:occurrences)
          changes[:occurrences]
        else
          active.occurrences
        end
        occurrences -= around unless occurrences.nil?

        new_recurrence = Recurrence.new(restart, occurrences, interval)

        active.occurrences = around

        historical << active
        @active = new_recurrence
      end

      self
    end

    private

    def reconfigure_active(**changes)
      active.interval = changes[:interval] unless changes[:interval].nil?
      active.occurrences = changes[:occurrences] if changes.key?(:occurrences)
    end

    def ensure_recurrence(maybe)
      return maybe.build if maybe.is_a?(Recurrence::Builder)

      maybe
    end

    def total_occurrences
      current_active_occurrence + active.occurrences
    end

    def current_active_occurrence
      historical.sum(0, &:occurrences)
    end
  end
end
