module DataObjects
  # Abstract class to read rows from a query result
  class Reader

    include Enumerable

    # The Connection on which the command will be run
    attr_reader :connection

    # Return the array of field names
    def fields
      raise NotImplementedError
    end

    def set_types(*column_types)
      raise NotImplementedError
    end

    # Yield each row to the given block as a DataObjects::Row
    def each
      raise NotImplementedError
    end


  end
end
