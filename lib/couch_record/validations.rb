module CouchRecord
  module Validations
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Validations
      include ActiveModel::Validations::Callbacks
    end

    module ClassMethods

      def validates_uniqueness_of(*attr_names)
        validates_with(UniquenessValidator, _merge_attributes(attr_names))
      end

    end

    class UniquenessValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        results = record.class.send("view_by_#{attribute}", value, :include_docs => false, :singular => false, :limit => 2)
        return if results.empty? || ( results.length == 1 && results[0]['id'] == record.id)
        record.errors.add(attribute, :taken, {:value => value})
      end
    end
  end
end