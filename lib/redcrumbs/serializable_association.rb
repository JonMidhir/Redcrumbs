module Redcrumbs
  module SerializableAssociation
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def serializable_association(name)
        raise ArgumentError unless name and [:creator, :target].include?(name)

        define_setter_for(name)
        define_getter_for(name)
        define_loader_for(name)
      end

      private

      # Define a setter, e.g. object.creator=
      #
      def define_setter_for(name)
        define_method("#{name}=") do |associated|
          instance_variable_set("@#{name}".to_sym, associated)

          assign_id_for(name, associated)
          assign_serialized_attributes(name, associated)
        end
      end


      # Define a getter, e.g. object.creator
      #
      def define_getter_for(name)
        define_method("#{name}") do
          instance_variable_get("@#{name}") or
          instance_variable_set("@#{name}", deserialize(name)) or
          instance_variable_set("@#{name}", load_associated(name))
        end
      end

      # Define method to force a re/load of the association from
      # the database, overwriting any memoized version.
      #
      def define_loader_for(name)
        define_method("full_#{name}") do
          instance_variable_set("@#{name}", load_associated(name))
        end
      end
    end


    # Load the association from the database.
    #
    def load_associated(name)
      return nil unless association_id = send("#{name}_id")

      klass = default_class_for(name)
      primary_key = default_primary_key_for(name)

      klass.where(primary_key => association_id).first
    end

    private

    # Assign the association id based on default primary key
    #
    def assign_id_for(name, associated)
      primary_key = default_primary_key_for(name)
      id = associated ? associated[primary_key] : nil

      send("#{name}_id=", id)
    end


    # Serialize and assign the association
    #
    def assign_serialized_attributes(name, associated)
      serialized = associated ? serialize(name, associated) : {}

      send("stored_#{name}=", serialized)
    end


    # Get the class name from the config options, e.g.
    # Redcrumbs.creator_class_sym
    #
    def default_class_for(name)
      Redcrumbs.send("#{name}_class_sym").to_s.classify.constantize
    end


    # Get the expected primary key for the association from
    # the config options.
    #
    def default_primary_key_for(name)
      Redcrumbs.send("#{name}_primary_key")
    end


    # Serializes a given object using the configuration options
    # for the association.
    #
    def serialize(name, associated)
      keys = Redcrumbs.send("store_#{name}_attributes").dup

      associated.attributes.select {|k,v| keys.include?(k.to_sym)}
    end


    # Returns a new instance of the associated object based on the
    # serialized attributes only.
    #
    def deserialize(name)
      properties = send("stored_#{name}")

      return nil unless properties.present?

      default_class_for(name).new(properties, :without_protection => true)
    end
  end
end