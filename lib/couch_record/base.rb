module CouchRecord
#  class Base < DelegateClass(CouchRest::Document)
  class Base < CouchRest::Document
    include CouchRecord::Types

    include ActiveModel::Validations
    extend ActiveModel::Naming

    extend ActiveModel::Callbacks
    define_model_callbacks :create, :destroy, :save, :update

    def initialize(doc)
      super(doc)
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
      #TODO
      false
    end

    def save(options = {})
      self.new? ? create(options) : update(options)
    end

    class << self
      def use_database(db_name)
        self.database = COUCHDB_SERVER.database(db_name.to_s)
      end

      def property(name, type = String, opts = {})
        define_method(name) do
          unless self[name].is_a? type
            self[name] = convert(self[name], type)
          end
          self[name]
        end
      end

      def timestamps!
        
      end

      def find(id)
        doc = database.get id
        new(doc)
      end


      def reduce_by(name, options = {})
        options[:reduce] = true
        map_by(name, options)
      end

      def map_by(name, options = {})
      end

      def find_by(name, options = {})
      end

      alias_method :view_by, :find_by
      
    end

  end
end
