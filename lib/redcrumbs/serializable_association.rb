require 'dm-core'
require 'dm-types'

module Redcrumbs
  module SerializableAssociation
    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
        include DataMapper::Resource unless self < DataMapper::Resource
      end
    end

    module ClassMethods
      def serializable_association(name)
        raise ArgumentError unless name and [:creator, :target, :subject].include?(name)

        property "stored_#{name}".to_sym, DataMapper::Property::Json, :lazy => false
        property "#{name}_id".to_sym, DataMapper::Property::Integer, :index => true, :lazy => false
        property "#{name}_type".to_sym, DataMapper::Property::String, :index => true, :lazy => false

        define_setter_for(name)
        define_getter_for(name)
        define_loader_for(name)
        define_load_state_getter(name)

        self
      end

      private

      # Define a setter, e.g. object.creator=
      #
      def define_setter_for(name)
        define_method("#{name}=") do |associated|
          instance_variable_set("@#{name}".to_sym, associated)

          assign_id_for(name, associated)
          assign_type_for(name, associated)
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


      # Define method to force a load of the association from
      # the database or return it if already loaded.
      #
      def define_loader_for(name)
        define_method("full_#{name}") do
          if send("has_loaded_#{name}?")
            instance_variable_get("@#{name}")
          else
            instance_variable_set("@#{name}_load_state", true)
            instance_variable_set("@#{name}", load_associated(name))
          end
        end
      end


      # Define method to check if association has been fully loaded
      # from the database.
      #
      def define_load_state_getter(name)
        instance_variable_set("@#{name}_load_state", false)

        define_method("has_loaded_#{name}?") do
          instance_variable_get("@#{name}_load_state")
        end
      end
    end


    # Load the association from the database.
    #
    def load_associated(name)
      return nil unless association_id = send("#{name}_id")

      # class_name = send("#{name}_type") || config_class_name_for(name)
      klass = class_name_for(name).classify.constantize

      primary_key = Redcrumbs.primary_key_for(name) || klass.primary_key

      klass.where(primary_key => association_id).first
    end

    private

    # Assign the association id based on default primary key
    #
    def assign_id_for(name, associated)
      id = if associated
        primary_key = Redcrumbs.primary_key_for(name) or associated.class.primary_key
        associated[primary_key]
      end

      send("#{name}_id=", id)
    end


    # Assign the association type based on default primary key
    #
    def assign_type_for(name, associated)
      type = associated ? associated.class.name : nil

      send("#{name}_type=", type)
    end


    # Serialize and assign the association
    #
    def assign_serialized_attributes(name, associated)
      serialized = associated ? serialize(name, associated) : {}

      send("stored_#{name}=", serialized)
    end


    # Return the class name for an association name.
    #
    def class_name_for(name)
      send("#{name}_type") or Redcrumbs.class_name_for(name)
    end


    # Serializes a given object by looking for its configuration options
    # or calling serialization method.
    #
    def serialize(name, associated)
      if name == :subject
        associated.serialized_as_redcrumbs_subject
      else
        keys = Redcrumbs.send("store_#{name}_attributes").dup

        associated.attributes.select {|k,v| keys.include?(k.to_sym)}
      end
    end


    # Returns a new instance of the associated object based on the
    # serialized attributes only.
    #
    def deserialize(name)
      properties = send("stored_#{name}")
      associated_id = send("#{name}_id")

      return nil unless properties.present? and associated_id

      class_name = send("#{name}_type")
      class_name ||= Redcrumbs.class_name_for(name) unless name == :subject

      instantiate_with_id(class_name, properties, associated_id)
    end


    # Return a properties hash that corresponds to the given class's
    # column names.
    #
    def clean_properties(klass, properties)
      properties.select {|k,v| klass.column_names.include?(k.to_s)}
    end


    def instantiate_with_id(class_name, properties, associated_id)
      klass = class_name.classify.constantize
      properties = clean_properties(klass, properties)

      associated = klass.new(properties, :without_protection => true)
      associated.id = associated_id
      associated
    end
  end
end