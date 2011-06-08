module CouchRecord
  module OrmAdapter
    extend ActiveSupport::Concern

    module ClassMethods
      # this is used by Devise via the orm_adapter interface
      def to_adapter
        self
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
