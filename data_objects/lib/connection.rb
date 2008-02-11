module DataObjects
  class Connection
  
    STATE_OPEN   = 0
    STATE_CLOSED = 1
  
    attr_reader :timeout, :database, :datasource, :server_version, :state
    
    attr_reader :db, :connection_string
    
    def self.new(uri)
      aquire(uri)
    end
    
    @connection_lock = Mutex.new
    @available_connections = Hash.new { |h,k| h[k] = [] }
    @reserved_connections = Set.new
    
    def self.connection_lock
      @mutex
    end
    
    def self.aquire(connection_string)
      conn = nil
      
      @connection_lock.synchronize do          
        unless @available_connections[connection_string].empty?
          conn = @available_connections[connection_string].pop
        else
          conn = allocate
          conn.send(:initialize, connection_string)
          at_exit { conn.close_socket }
        end
        
        @reserved_connections << conn
      end
      
      return conn
    end
    
    def self.release(connection)
      @connection_lock.synchronize do
        if @reserved_connections.delete?(connection)
          @available_connections[connection.connection_string] << connection
        end
      end
      return nil
    end
    
    def close
      self.class.release(self)
    end
    
    def initialize(connection_string)
    end
  
    def logger
      @logger || @logger = Logger.new(nil)
    end
  
    def logger=(value)
      @logger = value
    end
  
    def begin_transaction
      # TODO: Hook this up
      Transaction.new
    end
  
    def change_database(database_name)
      raise NotImplementedError
    end
  
    def close
      raise NotImplementedError
    end
  
    def create_command(text)
      Command.new(self, text)
    end
  
    def closed?
      @state == STATE_CLOSED
    end
  
  end
end