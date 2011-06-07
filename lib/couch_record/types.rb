module CouchRecord
  # String, Integer, Symbol, Time, Date, TrueClass, BigDecimal
  # Array, Hash

  module Types
    def convert_to_type(value, type)
      if type == Symbol
        value.to_sym
      elsif type == Time
        Time.iso8601 value
      elsif type == Date
        Date.iso8601 value
      elsif type == Integer
        value.to_i
      else
        type.new value
      end
    end

    def convert_for_save(value)
      case value
        when TrueClass, String, Integer
          value
        when Time
          value.utc.iso8601
        when Date
          value.iso8601
        when BigDecimal
          value.to_s('F')
        when Array
          value.map!(value) { |subval| convert_for_save(subval)}
        when Hash
          value.merge!(value) { |key, subval, subval2| convert_for_save(subval)}
        else
          value.to_s
      end
    end

  end
end
