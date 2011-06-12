module CouchRecord
  # String, Integer, Symbol, Time, Date, TrueClass, BigDecimal
  # Array, Hash

  module Types
    def convert_to_type(value, type)
      if value.nil? || value == true || value == false ||
          (type.is_a?(Array) && value[0].is_a?(type[0])) ||
          (!type.is_a?(Array) && value.is_a?(type))
        # no conversion necessary
        return value
      end

      if type.is_a?(Array)
        value.map { |subval| convert_to_type(subval, type[0]) }
      elsif type == Symbol
        value.to_sym
      elsif type == Time
        Time.iso8601 value
      elsif type == Date
        Date.iso8601 value
      elsif type == Integer
        value.to_i
      elsif type < CouchRecord::Base
        type.new value, :parent_record => self, :raw => @_raw
      else
        type.new value
      end
    end

    def convert_for_save(value)
      if value.nil? || value.is_a?(String) || value.is_a?(Integer) || value.is_a?(TrueClass) || value.is_a?(FalseClass)
        value
      elsif value.is_a?(Time)
        value.utc.iso8601
      elsif value.is_a?(Date)
        value.iso8601
      elsif value.is_a?(BigDecimal)
        value.to_s('F')
      elsif value.is_a?(Array)
        value.map! { |subval| convert_for_save(subval) }
      elsif value.is_a?(Hash)
        value.merge!(value) { |key, subval, subval2| convert_for_save(subval) }
      else
        value.to_s
      end
    end

  end
end
