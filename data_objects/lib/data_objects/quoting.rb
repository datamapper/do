module DataObjects

  module Quoting

    def quote_value(value)
      return 'NULL' if value.nil?

      case value
        when Numeric then quote_numeric(value)
        when String then quote_string(value)
        when Time then quote_time(value)
        when DateTime then quote_datetime(value)
        when Date then quote_date(value)
        when TrueClass, FalseClass then quote_boolean(value)
        when Array then quote_array(value)
        when Range then quote_range(value)
        when Symbol then quote_symbol(value)
        when Regexp then quote_regexp(value)
        when ::Extlib::ByteArray then quote_byte_array(value)
        when Class then quote_class(value)
        else
          if value.respond_to?(:to_sql)
            value.to_sql
          else
            raise "Don't know how to quote #{value.class} objects (#{value.inspect})"
          end
      end
    end

    def quote_symbol(value)
      quote_string(value.to_s)
    end

    def quote_numeric(value)
      value.to_s
    end

    def quote_string(value)
      "'#{value.gsub("'", "''")}'"
    end

    def quote_class(value)
      quote_string(value.name)
    end

    def quote_time(value)
      offset = value.utc_offset
      if offset >= 0
        offset_string = "+#{sprintf("%02d", offset / 3600)}:#{sprintf("%02d", (offset % 3600) / 60)}"
      elsif offset < 0
        offset_string = "-#{sprintf("%02d", -offset / 3600)}:#{sprintf("%02d", (-offset % 3600) / 60)}"
      end
      "'#{value.strftime('%Y-%m-%dT%H:%M:%S')}" << (value.usec > 0 ? ".#{value.usec.to_s.rjust(6, '0')}" : "") << offset_string << "'"
    end

    def quote_datetime(value)
      "'#{value.dup}'"
    end

    def quote_date(value)
      "'#{value.strftime("%Y-%m-%d")}'"
    end

    def quote_boolean(value)
      value.to_s.upcase
    end

    def quote_array(value)
      "(#{value.map { |entry| quote_value(entry) }.join(', ')})"
    end

    def quote_range(value)
      "#{quote_value(value.first)} AND #{quote_value(value.last)}"
    end

    def quote_regexp(value)
      quote_string(value.source)
    end

    def quote_byte_array(value)
      quote_string(value.source)
    end

  end

end
