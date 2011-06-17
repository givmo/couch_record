module CouchRecord
  module OrmAdapter
    extend ActiveSupport::Concern

    module ClassMethods
      # this is used by Devise via the orm_adapter interface
      def to_adapter
        self
      end

      def get(id)
        #TODO 2011-07-01 this is only necessary because old remember cookies store an array
        id = id[0] if id.is_a? Array
        find(id)
      end

      def get!(id)
        record = get(id)
        raise RestClient::ResourceNotFound unless record
        record
      end

      # Find the first instance matching conditions
      # this is used by Devise via the orm_adapter interface
      def find_first(conditions)
        if conditions.keys.first == :id
          get(conditions.values.first)
        else
          send("find_by_#{conditions.keys.first}", {:key => conditions.values.first, :singular => true})
        end
      end

    end
  end
end
