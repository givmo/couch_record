module CouchRecord
  module Types
    def convert(value, type)
      case type
        when Symbol
          value.to_sym
        when Time
          Time.iso8601 value
        when Integer
          value.to_i
        else
          type.new value
      end
    end
  end
end
