module DataObjects
  class Transaction
  
    attr_reader :connection
  
    def initialize(conn)
      @connection = conn
    end
  
    # Commits the transaction
    def commit
      raise NotImplementedError
    end
  
    # Rolls back the transaction
    def rollback(savepoint = nil)
      raise NotImplementedError
    end
  
    # Creates a savepoint for rolling back later (not commonly supported)
    def save(name)
      raise NotImplementedError
    end
  
  end
end