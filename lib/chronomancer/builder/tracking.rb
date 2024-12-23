# frozen_string_literal: true

module Chronomancer
  module Builder
    module Tracking
      class << self
        def extended(base)
          base.extend(ClassMethods)
          base.include(InstanceMethods)
        end
      end

      module ClassMethods
        def conflicts(*method_names)
          @conflicts ||= []
          @conflicts << method_names
        end

        def tracked_methods
          @tracked_methods ||= {}
        end

        def define_tracked_method(name, store, collect, default, &block)
          define_method(name) do |*args|
            track_call(__method__)
            check_conflicts(__method__)

            store_var = "@#{store}"

            value = if block_given?
              instance_exec(*args, &block)
            else
              args.first
            end

            if collect
              instance_variable_set(store_var, []) unless instance_variable_defined?(store_var)
              instance_variable_get(store_var) << value
            else
              instance_variable_set(store_var, value)
            end

            self
          end
        end
      end

      module InstanceMethods
        def track_call(name)
          @called ||= Hash.new(0)
          @called[name] += 1

          if singular_method?(name) && @called[name] > 1
            raise Chronomancer::Error, "#{name} can only be called once"
          end
        end

        def singular_method?(name)
          !self.class.tracked_methods[name][:multiple]
        end

        def check_conflicts(method_name)
          self.class.conflicts.each do |conflict_group|
            next unless conflict_group.include?(method_name)

            conflicting_method = conflict_group.find do |conflicting_method|
              conflicting_method != method_name &&
                @called&.key?(conflicting_method)
            end

            if conflicting_method.present?
              raise Chronomancer::Error, "#{method_name} and #{conflicting_method} are mutually exclusive"
            end
          end
        end
      end
    end
  end
end
