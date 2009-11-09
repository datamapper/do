module DataObjects
  # Abstract class to read rows from a query result
  class Reader

    include Enumerable

    # Return the array of field names
    def fields
      raise NotImplementedError.new
    end

    # Return the array of field values for the current row. Not legal after next! has returned false or before it's been called
    def values
      raise NotImplementedError.new
    end

    # Close the reader discarding any unread results.
    def close
      raise NotImplementedError.new
    end

    # Discard the current row (if any) and read the next one (returning true), or return nil if there is no further row.
    def next!
      raise NotImplementedError.new
    end

    # Return the number of fields in the result set.
    def field_count
      raise NotImplementedError.new
    end

    # Yield each row to the given block as a Hash
    def each
      begin
        while next!
          row = {}
          fields.each_with_index { |field, index| row[field] = values[index] }
          yield row
        end
      ensure
        close
      end
      self
    end

  end
end
