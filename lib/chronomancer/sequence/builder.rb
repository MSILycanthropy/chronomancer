# frozen_string_literal: true

module Chronomancer
  class Sequence
    class Builder
      attr_reader :recurrence_builder

      def initialize
        @recurrence_builder = Recurrence::Builder.new
      end

      def build
        Sequence.new(@recurrence_builder.build)
      end

      (Recurrence::Builder.instance_methods - Class.instance_methods - [
        :build,
        :validate_all!,
        :validate_required_fields!,
        :check_conflicts,
        :singular_method?,
        :track_call,
      ]).each do |method|
        define_method(method) do |*args, **kwargs, &block|
          @recurrence_builder.send(method, *args, **kwargs, &block)

          self
        end
      end

      # :nocov:
      def respond_to_missing?(method)
        true
      end
      # :nocov:

      def method_missing(method, ...)
        build.send(method, ...)
      end
    end
  end
end
