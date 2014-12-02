module Redcrumbs
  module SerializableAssociation
    class PolymorphicAssociation
      attr_reader :id, :class_name, :reflection

      def initialize(class_name = nil, id = nil)
        @class_name, @id = class_name, id
      end


      def self.with(associated)
        if associated
          new(associated.class.name, associated.id).tap do |association|
            association.set_reflection(associated)
          end
        else
          new
        end
      end


      def load
        if loaded?
          @reflection
        else
          load!
        end
      end


      def load!
        if loadable?
          @reflection = class_name.constantize.find(id)
        end
      end


      def loaded?
        !!@reflection
      end


      def loadable?
        class_name and id
      end


      def set_reflection(reflection)
        @class_name = reflection.class.name
        @id         = reflection.id
        @reflection = reflection
      end
    end
  end
end