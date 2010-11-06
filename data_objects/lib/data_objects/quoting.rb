module DataObjects

  module Quoting

    # Quote a value of any of the recognised data types
    def quote_value(value)
      return 'NULL' if value.nil?

      case value
        when Numeric then quote_numeric(value)
        when ::DataObjects::ByteArray then quote_byte_array(value)
        when String then quote_string(value)
        when Time then quote_time(value)
        when DateTime then quote_datetime(value)
        when Date then quote_date(value)
        when TrueClass, FalseClass then quote_boolean(value)
        when Array then quote_array(value)
        when Range then quote_range(value)
        when Symbol then quote_symbol(value)
        when Regexp then quote_regexp(value)
        when Class then quote_class(value)
        else
          if value.respond_to?(:to_sql)
            value.to_sql
          else
            raise "Don't know how to quote #{value.class} objects (#{value.inspect})"
          end
      end
    end

    # Convert the Symbol to a String and quote that
    def quote_symbol(value)
      quote_string(value.to_s)
    end

    # Convert the Numeric to a String and quote that
    def quote_numeric(value)
      value.to_s
    end

    # Quote a String for SQL by doubling any embedded single-quote characters
    def quote_string(value)
      "'#{value.gsub("'", "''")}'"
    end

    # Quote a class by quoting its name
    def quote_class(value)
      quote_string(value.name)
    end

    # Convert a Time to standard YMDHMS format (with microseconds if necessary)
    def quote_time(value)
      offset = value.utc_offset
      if offset >= 0
        offset_string = "+#{sprintf("%02d", offset / 3600)}:#{sprintf("%02d", (offset % 3600) / 60)}"
      elsif offset < 0
        offset_string = "-#{sprintf("%02d", -offset / 3600)}:#{sprintf("%02d", (-offset % 3600) / 60)}"
      end
      "'#{value.strftime('%Y-%m-%dT%H:%M:%S')}" << (value.usec > 0 ? ".#{value.usec.to_s.rjust(6, '0')}" : "") << offset_string << "'"
    end

    # Quote a DateTime by relying on it's own to_s conversion
    def quote_datetime(value)
      "'#{value.dup}'"
    end

    # Convert a Date to standard YMD format
    def quote_date(value)
      "'#{value.strftime("%Y-%m-%d")}'"
    end

    # Quote true, false as the strings TRUE, FALSE
    def quote_boolean(value)
      value.to_s.upcase
    end

    # Quote an array as a list of quoted values
    def quote_array(value)
      "(#{value.map { |entry| quote_value(entry) }.join(', ')})"
    end

    # Quote a range by joining the quoted end-point values with AND.
    # It's not clear whether or when this is a useful or correct thing to do.
    def quote_range(value)
      "#{quote_value(value.first)} AND #{quote_value(value.last)}"
    end

    # Quote a Regex using its string value. Note that there's no attempt to make a valid SQL "LIKE" string.
    def quote_regexp(value)
      quote_string(value.source)
    end

    def quote_byte_array(value)
      quote_string(value)
    end

    private

    # Escape a string of SQL with a set of arguments.
    # The first argument is assumed to be the SQL to escape,
    # the remaining arguments (if any) are assumed to be
    # values to escape and interpolate.
    #
    # ==== Examples
    #   escape_sql("SELECT * FROM zoos")
    #   # => "SELECT * FROM zoos"
    #
    #   escape_sql("SELECT * FROM zoos WHERE name = ?", "Dallas")
    #   # => "SELECT * FROM zoos WHERE name = `Dallas`"
    #
    #   escape_sql("SELECT * FROM zoos WHERE name = ? AND acreage > ?", "Dallas", 40)
    #   # => "SELECT * FROM zoos WHERE name = `Dallas` AND acreage > 40"
    #
    # ==== Warning
    # This method is meant mostly for adapters that don't support
    # bind-parameters.
    def escape_sql(query, args)
      sql = query.dup
      vars = args.dup

      replacements = 0
      mismatch     = false

      sql.gsub!(/'[^']*'|"[^"]*"|`[^`]*`|\?/) do |x|
        next x unless x == '?'
        replacements += 1
        if vars.empty?
          mismatch = true
        else
          var = vars.shift
          quote_value(var)
        end
      end

      if !vars.empty? || mismatch
        raise ArgumentError, "Binding mismatch: #{args.size} for #{replacements}"
      else
        sql
      end
    end

  end

end
