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

    class_attribute :_save_timestamps

    def initialize(attributes = nil, options = nil)
      if options && options[:parent_record]
        self.parent_record = options[:parent_record]
      end

      @_raw = false

      if (attributes)
        if options && options[:raw]
          _raw { super(attributes) }
        else
          self.attributes = attributes
        end
      end

    end

    def _raw
      @_old_raw ||= []
      @_old_raw.push @_raw
      @_raw = true
      result = yield
      @_raw = @_old_raw.pop
      result
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
      id && JoinableString.new(id)
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
      if !@_raw && !attribute_changed?(attr) && self[attr] != to
        begin
          value = self[attr]
          value = value.duplicable? ? value.clone : value
        rescue TypeError, NoMethodError
        end

        changed_attributes[attr] = value
        self.parent_record.attribute_will_change_to!(self.parent_attr, nil) if self.parent_record
      end
    end


    def attributes=(attributes)
      attributes = self.sanitize_for_mass_assignment(attributes) unless @_raw
      attributes.each_pair do |attr, value|
        self.send("#{attr}=", value)
      end
    end

    def merge_attributes(attributes)
      attributes = self.sanitize_for_mass_assignment(attributes) unless @_raw
      attributes.each_pair do |attr, value|
        if self.respond_to? "#{attr}_merge"
          self.send("#{attr}_merge", value)
        else
          # this is needed for attrs that aren't CouchRecord properties
          self.send("#{attr}=", value)
        end
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

        attr_accessible attr if options[:accessible]
        attr_protected attr if options[:protected]

        define_method(attr) do
          _raw do
            self[attr] = convert_to_type(self[attr], type)

            if self[attr].nil?
              default = _default_value(type, options)
              self.send("#{attr}=", default) unless default.nil?
            end
          end

          self[attr]
        end

        define_method("#{attr}=") do |value|
          self[attr] = convert_to_type(value, type)
        end

        define_method("#{attr}_merge") do |value|
          current = self.send attr
          if current && value && type.is_a?(Class) && type < CouchRecord::Base
            current.merge_attributes(value)
          elsif current && value && type.is_a?(Array)
            # deal with array attrs being pass as hashes, like when we use FormHelper
            if value.is_a?(Array)
              #trim the current set of values if there are more than the new set
              current.slice!(value.length..-1)
              enum = value.each_index
            else
              enum = value.each_key
            end

            enum.each do |key|
              subval = value[key]
              i = key.to_i
              if current[i] && subval && type[0] < CouchRecord::Base
                current[i].merge_attributes(subval)
              else
                current[i] = convert_to_type(subval, type[0])
              end
            end
          elsif current && value && type == Hash
            value.each_pair do |key, subval|
              if current[key] && subval && current[key].respond_to?(:merge_attributes)
                current[key].merge_attributes(subval)
              else
                current[key] = subval
              end
            end
          else
            self[attr] = convert_to_type(value, type)
          end

          self[attr]
        end

        if type.is_a?(Array) && type[0] < CouchRecord::Base
          define_method("#{attr}_attributes=") do |attributes|
            self.send("#{attr}_merge", attributes)
          end
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
        self._save_timestamps = true
        property :created_at, Time
        property :updated_at, Time
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
