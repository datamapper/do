require 'uri'
require 'set'

begin
  require 'fastthread'
rescue LoadError
end

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
      DataObjects.const_get(uri.scheme.capitalize)::Connection.acquire(uri)
    end
    
    def self.acquire(connection_uri)
      conn = nil
      connection_string = connection_uri.to_s
      
      @connection_lock.synchronize do          
        unless @available_connections[connection_string].empty?
          conn = @available_connections[connection_string].pop
        else
          conn = allocate
          conn.send(:initialize, connection_uri)
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
      @uri.to_s
    end
    
    def initialize(uri)
      raise NotImplementedError.new
    end

    def real_close
      raise NotImplementedError.new
    end
    
    def create_command(text)
      concrete_command.new(self, text)
    end
    
    private
    def concrete_command
      @concrete_command || begin
        
        class << self
          private
          def concrete_command
            @concrete_command
          end
        end

        @concrete_command = DataObjects::const_get(self.class.name.split('::')[-2]).const_get('Command')
      end
    end
      
  end
end
