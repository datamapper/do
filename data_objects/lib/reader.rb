module DataObjects
  class Reader
    include Enumerable
  
    attr_reader :field_count, :records_affected, :fields
  
    def each
      raise NotImplementedError
    end
  
    def has_rows?
      @has_rows
    end
  
    def current_row
      ret = []
      field_count.times do |i|
        ret[i] = item(i)
      end
      ret
    end
  
    def open?
      @state != STATE_CLOSED
    end
  
    def close        
      real_close
      @reader = nil
      @state = STATE_CLOSED
      true
    end
  
    def real_close
      raise NotImplementedError
    end
  
    # retrieves the Ruby data type for a particular column number
    def data_type_name(col)
      raise ReaderClosed, "You cannot ask for metadata once the reader is closed" if state_closed?      
    end
  
    # retrieves the name of a particular column number
    def name(col)
      raise ReaderClosed, "You cannot ask for metadata once the reader is closed" if state_closed?      
    end
  
    # retrives the index of the column with a particular name
    def get_index(name)
      raise ReaderClosed, "You cannot ask for metadata once the reader is closed" if state_closed?
    end
  
    def item(idx)
      raise ReaderClosed, "You cannot ask for information once the reader is closed" if state_closed?
    end

    # returns an array of hashes containing the following information
    #            
    # name:         the column name
    # index:        the index of the column
    # max_size:     the maximum allowed size of the data in the column
    # precision:    the precision (for column types that support it)
    # scale:        the scale (for column types that support it)
    # unique:       boolean specifying whether the values must be unique
    # key:          boolean specifying whether this column is, or is part
    #               of, the primary key
    # catalog:      the name of the database this column is part of
    # base_name:    the original name of the column (if AS was used,
    #               this will provide the original name)
    # schema:       the name of the schema (if supported)
    # table:        the name of the table this column is part of
    # data_type:    the name of the Ruby data type used
    # allow_null:   boolean specifying whether nulls are allowed
    # db_type:      the type specified by the DB
    # aliased:      boolean specifying whether the column has been
    #               renamed using AS
    # calculated:   boolean specifying whether the field is calculated
    # serial:       boolean specifying whether the field is a serial
    #               column
    # blob:         boolean specifying whether the field is a BLOB
    # readonly:     boolean specifying whether the field is readonly
    def get_schema
      raise ReaderClosed, "You cannot ask for metadata once the reader is closed" if state_closed?
    end
  
    # specifies whether the column identified by the passed in index
    # is null.
    def null?(idx)
      raise ReaderClosed, "You cannot ask for column information once the reader is closed" if state_closed?
    end
  
    # Consumes the next result. Returns true if a result is consumed and
    # false if none is
    def next
      raise ReaderClosed, "You cannot increment the cursor once the reader is closed" if state_closed?
    end
  
    protected
    def state_closed?
      @state == STATE_CLOSED
    end
  
    def native_type
      raise ReaderClosed, "You cannot check the type of a column once the reader is closed" if state_closed?
    end
  
  end
end