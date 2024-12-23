# frozen_string_literal: true

require "chronomancer/builder/tracking"
require "chronomancer/builder/validation"

module Chronomancer
  module Builder
    class << self
      def included(base)
        base.class_eval do
          extend(Tracking)
          extend(Validation)
          extend(ClassMethods)
        end
      end
    end

    def initialize
      self.class.tracked_methods.each do |_, data|
        store_var = "@#{data[:store]}"
        value = instance_variable_get(store_var)

        default_value = if value.nil?
          if data[:default].respond_to?(:call)
            data[:default].call
          else
            data[:default]
          end
        end

        instance_variable_set(store_var, default_value) if default_value.present?
      end
    end

    module ClassMethods
      def build(&block)
        define_method(:build) do
          validate_required_fields!
          validate_all!

          instance_eval(&block)
        end
      end

      def option(name, store: nil, default: nil, &block)
        define_option(name, store, false, default, &block)
      end

      def options(name, store: nil, default: nil, &block)
        define_option(name, store, true, default, &block)
      end

      private

      def define_option(name, store, multiple, default, &block)
        store ||= name

        name = name.to_s.singularize.to_sym if multiple

        @tracked_methods ||= {}
        @tracked_methods[name] = { multiple: multiple, store: store, default: default }

        define_tracked_method(name, store, multiple, default, &block)
      end
    end

    private

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
