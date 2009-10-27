module DataObjects
  # Abstract class to read rows from a query result
  class Reader

    include Enumerable

    ##
    # Returns the array of field names
    #
    # Note, that relational databases may use upper case identifiers internally,
    # but that field names should always be downcased by Driver implementations.
    #
    # @return [Array<String>] the field names (in lower case)
    def fields
      raise NotImplementedError.new
    end

    ##
    # Returns the array of field values for the current row.
    #
    # Not legal after next! has returned false or before it's been called
    #
    # @return [Array] the values for the current row
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

    # Yield each row to the given block as a struct
    def each
      begin
        while next!
          yield struct.new(*values)
        end
      ensure
        close
        self
      end
    end

    private

    def struct
      @struct ||= Struct.new(*fields.map {|f| f.to_sym})
    end

  end
end
