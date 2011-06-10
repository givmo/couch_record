module CouchRecord
  class Base < CouchRest::Document
    include CouchRecord::Types
    include CouchRecord::Query
    include CouchRecord::Persistence
    include CouchRecord::Validations
    include CouchRecord::Associations
    include CouchRecord::OrmAdapter

    include ActiveModel::Dirty
    include ActiveModel::MassAssignmentSecurity
    extend ActiveModel::Naming
    extend ActiveModel::Callbacks
    define_model_callbacks :create, :destroy, :save, :update

    attr_accessor :parent_record

    def initialize(hash = {}, options = nil)
      self.parent_record = options[:parent_record] if options && options[:parent_record]

      if options && options[:raw]
        super(hash)
      else
        hash.each_pair do |attr, value|
          self.send("#{attr}=", value)
        end
      end
    end

    def id
      if self.parent_record
        self.parent_record.id
      else
        super
      end
    end

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
        self.database = CouchRecord::Database.new(CouchRecord.server, db_name.to_s)
      end

      def property(attr, type = String, options = {})
        unless options.has_key?(:default)
          if type.is_a? Array
            options[:default] = []
          elsif type.is_a? Hash
            options[:default] = {}
          end
        end

        define_method(attr) do
          self[attr] = convert_to_type(self[attr], type)

          if self[attr].nil?
            self[attr] = options[:default].duplicable? ? options[:default].clone : options[:default]
          end

          self[attr]
        end

        define_method("#{attr}=") do |value|
          value = convert_to_type(value, type)
          attribute_will_change!(attr) unless self[attr] == value
          self[attr] = value
        end

        define_method("#{attr}_changed?") do
          attribute_changed?(attr)
        end

        define_method("#{attr}_change") do
          attribute_change(attr)
        end

        define_method("#{attr}_was") do
          attribute_was(attr)
        end

        define_method("#{attr}_changed?") do
          attribute_changed?(attr)
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
