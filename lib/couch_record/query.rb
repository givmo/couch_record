module CouchRecord
  module Query
    extend ActiveSupport::Concern



    module ClassMethods
      def find(id)
        database.get_type id, self
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
