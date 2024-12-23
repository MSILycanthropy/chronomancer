# frozen_string_literal: true

module Chronomancer
  module Builder
    module Validation
      class << self
        def extended(base)
          base.extend(ClassMethods)
          base.include(InstanceMethods)
        end
      end

      module ClassMethods
        def validate(&block)
          @validations ||= []
          @validations << block
        end

        def validations
          @validations ||= []
        end

        def requires(*fields)
          @required_fields ||= []
          @required_fields.concat(fields)
        end

        def required_fields
          @required_fields ||= []
        end
      end

      module InstanceMethods
        def validate_all!
          self.class.validations.each do |validation|
            instance_eval(&validation)
          end
        end

        def validate_required_fields!
          missing = self.class.required_fields.select do |field|
            !instance_variable_defined?(:"@#{field}")
          end

          if missing.any?
            raise Chronomancer::Error, "missing required fields: #{missing.join(", ")}"
          end
        end
      end
    end
  end
end
