module CouchRecord
  class Base < CouchRest::Document
    include CouchRecord::Types
    include CouchRecord::Query
    include CouchRecord::Persistence
    include CouchRecord::Validations
    include CouchRecord::Associations
    include CouchRecord::OrmAdapter
    include CouchRecord::TrackableContainer::TrackableHash

    include ActiveModel::Dirty
    include ActiveModel::MassAssignmentSecurity
    extend ActiveModel::Naming
    extend ActiveModel::Callbacks
    define_model_callbacks :create, :destroy, :save, :update

    def initialize(attributes = {}, options = nil)
      if options && options[:parent_record]
        self.parent_record = options[:parent_record]
      end

      @_track_changes = true

      if options && options[:raw]
        _dont_track_changes { super(attributes) }
      else
        set_attributes(attributes)
      end

    end

    def _dont_track_changes
      @_track_changes = false
      yield
      @_track_changes = true
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
      # this is a hack for FormHelper because it expects an Array
      JoinableString.new id
    end

    # Returns a string representing the object's key suitable for use in URLs,
    # or nil if persisted? is false
    def to_param
      id
    end

    def persisted?
      !new?
    end

    def attribute_will_change_to!(attr, to)
      if @_track_changes && !attribute_changed?(attr) && self[attr] != to
        attribute_will_change!(attr)
        self.parent_record.attribute_will_change_to!(self.parent_attr, nil) if self.parent_record
      end
    end


    def set_attributes(attributes)
      attributes.each_pair do |attr, value|
        self.send("#{attr}=", value)
      end
    end

    def _default_value(type, options)
      if options.has_key?(:default)
        # explicit defaults
        options[:default].duplicable? ? options[:default].clone : options[:default]
      else
        # implicit defaults
        if type.is_a? Array
          []
        elsif type < CouchRecord::Base
          type.new nil, :parent_record => self
        elsif type == Hash
          {}
        end
      end
    end

    class << self

      def use_database(db_name)
        self.database = CouchRecord::Database.new(CouchRecord.server, db_name.to_s)
      end

      def property(attr, type = String, options = {})
        _defaulted_properties << attr if options.has_key?(:default)

        define_method(attr) do
          _dont_track_changes do
            self[attr] = convert_to_type(self[attr], type)

            if self[attr].nil?
              default = _default_value(type, options)
              self.send("#{attr}=", default) unless default.nil?
            end
          end

          self[attr]
        end

        define_method("#{attr}=") do |value|
          value = convert_to_type(value, type)
#          attribute_will_change_to!(attr, value)
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

      def _defaulted_properties
        @_defaulted_properties ||= []
      end

    end

  end

  class JoinableString < String
    def join(sep = $,)
      self
    end
  end

end
