module CouchRecord
  class Base < CouchRest::Document
    include CouchRecord::Types
    include CouchRecord::Query
    include CouchRecord::Persistence

    include ActiveModel::Validations
    extend ActiveModel::Naming

    extend ActiveModel::Callbacks
    define_model_callbacks :create, :destroy, :save, :update

    def to_model
      self
    end

    def to_key
      id
    end

    # Returns a string representing the object's key suitable for use in URLs,
    # or nil if persisted? is false
    def to_param
      id
    end

    def persisted?
      !new?
    end

    class << self
      def use_database(db_name)
        self.database = CouchRecord::Database.new(COUCHDB_SERVER, db_name.to_s)
      end

      def property(name, type = String, opts = {})

        define_method(name) do
          value = self[name]
          if value && !value.is_a?(type)
            self[name] = value = convert_to_type(value, type)
          end

          value = opts[:default] if value.nil?
          value
        end

        define_method(name.to_s+'=') do |value|
          if value && !value.is_a?(type)
            value = convert_to_type(value, type)
          end
          self[name] = value
        end

      end

      def timestamps!
        @_save_timestamps = true
        property :created_at, Time
        property :updated_at, Time
      end

      def _save_timestamps?
        @_save_timestamps
      end

    end

  end
end
