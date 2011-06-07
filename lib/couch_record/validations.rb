module CouchRecord
  module Validations
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Validations
      include ActiveModel::Validations::Callbacks
    end

    module ClassMethods

      def validates_uniqueness_of(property_name, options = {})
        options[:property_name] = property_name
        validates_with(UniquenessValidator, options)
      end

    end

    class UniquenessValidator < ActiveModel::Validator
      def validate(record)
        results = record.class.send("map_by_#{options[:property_name]}", :singular => false)
        results.empty? || ( results.length == 1 && results[0]['id'] == record.id)
      end
    end
  end
end