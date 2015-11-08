require 'dm-core'
require 'dm-types'
require 'redcrumbs/polymorphic_association'

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

        property "stored_#{name}".to_sym, DataMapper::Property::Json, :lazy => false, :writer => :private
        property "#{name}_id".to_sym, DataMapper::Property::Integer, :index => true, :lazy => false, :writer => :private
        property "#{name}_type".to_sym, DataMapper::Property::String, :index => true, :lazy => false, :writer => :private

        define_setter_for(name)
        define_getter_for(name)
        define_loader_for(name)

        self
      end

      private

      # Define a getter, e.g. object.creator
      #
      def define_getter_for(name)
        define_method("#{name}") do
          instance_variable_get("@#{name}") or
          instance_variable_set("@#{name}", deserialize(name)) or
          instance_variable_set("@#{name}", named_association(name).load)
        end
      end


      # Define a setter, e.g. object.creator=
      #
      def define_setter_for(name)
        define_method("#{name}=") do |associated|
          association = PolymorphicAssociation.with(associated)

          instance_variable_set "@#{name}_association", association
          instance_variable_set "@#{name}", associated

          attribute_set "#{name}_id",     association.id
          attribute_set "#{name}_type",   association.class_name
          attribute_set "stored_#{name}", serialize(name, associated)
        end
      end


      # Define method to force a load of the association from
      # the database or return it if already loaded.
      #
      def define_loader_for(name)
        define_method("full_#{name}") do
          named_association(name).load
        end
      end
    end


    def named_association(name)
      association   = instance_variable_get("@#{name}_association")
      association ||= PolymorphicAssociation.new(class_name_for(name), self["#{name}_id"])

      instance_variable_set("@#{name}_association", association)
    end


    private


    # Return the class name for an association name.
    #
    def class_name_for(name)
      self["#{name}_type"] or Redcrumbs.class_name_for(name)
    end


    # Serializes a given object by looking for its configuration options
    # or calling serialization method.
    #
    def serialize(name, associated)
      return {} unless associated

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
      properties = self["stored_#{name}"]
      associated_id = self["#{name}_id"]

      return nil unless properties.present? and associated_id

      class_name = self["#{name}_type"]
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