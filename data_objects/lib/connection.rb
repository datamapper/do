require 'uri'
require 'set'
require 'fastthread'
require 'logger'

module DataObjects
  class Connection
    
    def self.inherited(base)
      base.instance_variable_set('@connection_lock', Mutex.new)
      base.instance_variable_set('@available_connections', Hash.new { |h,k| h[k] = [] })
      base.instance_variable_set('@reserved_connections', Set.new)
    end
    
    def self.new(uri)
      uri = uri.is_a?(String) ? URI::parse(uri) : uri
      DataObjects.const_get(uri.scheme.capitalize)::Connection.aquire(uri.to_s)
    end
    
    def self.aquire(connection_string)
      conn = nil
      
      @connection_lock.synchronize do          
        unless @available_connections[connection_string].empty?
          conn = @available_connections[connection_string].pop
        else
          conn = allocate
          conn.send(:initialize, connection_string)
          at_exit { conn.real_close }
        end
        
        @reserved_connections << conn
      end
      
      return conn
    end
    
    def self.release(connection)
      @connection_lock.synchronize do
        if @reserved_connections.delete?(connection)
          @available_connections[connection.to_s] << connection
        end
      end
      return nil
    end
    
    def close
      self.class.release(self)
    end
        
    #####################################################
    # Standard API Definition
    #####################################################
    def to_s
      @uri
    end
    
    def initialize(uri)
      raise NotImplementedError.new
    end

    def begin_transaction
      raise NotImplementedError.new
    end
    
    def real_close
      raise NotImplementedError.new
    end
    
    def create_command(text)
      Command.new(self, text)
    end
      
  end
end