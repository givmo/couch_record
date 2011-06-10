module CouchRecord
  module Associations
    extend ActiveSupport::Concern

    def _associated_records
      @_associated_records ||= {}
    end

    module ClassMethods

      def belongs_to(name, options = {})
        define_method(name) do
          associated_id = self.send("#{name}_id")
          return nil if associated_id.nil?

          associated_record = _associated_records[name]
          return associated_record if associated_record && associated_record.id == associated_id

          _associated_records[name] = options[:class].find associated_id
        end
      end

    end

  end
end
