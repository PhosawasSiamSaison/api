module UnscopedAssociations
  extend ActiveSupport::Concern

  module ClassMethods
    def belongs_to_with_unscoped(model, options = {})
      belongs_to_without_unscoped(model, options.reject { |k, v| k == :unscoped })

      if options[:unscoped]
        define_method "#{model}_with_unscoped" do
          model_name =
            if options.include?(:class_name)
              options[:class_name]
            elsif options[:polymorphic]
              if options[:foreign_type]
                send(options[:foreign_type].to_s)
              else
                send("#{model.to_s}_type")
              end
            else
              model
            end
          model_name.to_s.camelize.constantize.unscoped do
            send("#{model}_without_unscoped")
          end
        end

        alias_method "#{model}_without_unscoped", model
        alias_method model, "#{model}_with_unscoped"
      end
    end
  end

  included do
    class << self
      alias_method :belongs_to_without_unscoped, :belongs_to
      alias_method :belongs_to, :belongs_to_with_unscoped
    end
  end
end