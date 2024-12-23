# frozen_string_literal: true

module Chronomancer
  class Recurrence
    class Builder
      include Chronomancer::Builder

      build do
        calculate_occurrences_from_end_date

        Recurrence.new(@start.to_time, @occurrences, @interval)
      end

      requires :interval

      # starting
      option :starting, store: :start, default: -> { Time.current }

      # interval
      conflicts :daily, :weekly, :monthly, :yearly

      option :daily, store: :interval do |_|
        1.day
      end

      option :weekly, store: :interval do |_|
        1.week
      end

      option :monthly, store: :interval do |_|
        1.month
      end

      option :yearly, store: :interval do |_|
        1.year
      end

      option :every, store: :interval

      # occurrences
      conflicts :total, :forever, :until

      option :total, store: :occurrences

      option :forever, store: :occurrences do |_|
        nil
      end

      option :until, store: :end

      validate do
        raise Chronomancer::Error, "occurrences must be positive" if @occurrences&.negative?
      end

      private

      def calculate_occurrences_from_end_date
        return if @end.nil?
        return if @occurrences.present?

        start_time = @start.to_time
        end_time = @end.to_time

        intervals = ((end_time - start_time) / @interval).ceil

        occurrences = intervals + 1

        last_occurrence = start_time + (@interval * intervals)

        occurrences -= 1 if last_occurrence > end_time

        @occurrences = occurrences
      end
    end
  end
end
