class Object
  
  module Pooling
    
    class MustImplementDisposeError < StandardError
    end
    
    @size = 4
    
    def self.size
      @size
    end
    
    def self.size=(value)
      @size = size
    end
    
    def self.included(target)
      target.extend(ClassMethods)
    end
    
    def release
      self.class.release(self)
    end      
    
    class Pools
      
      attr_reader :type
      
      def initialize(type)
        @type = type
        @pools = Hash.new { |h,k| h[k] = Pool.new(@type) }
      end
      
      def flush!
        @pools.each_pair do |args,pool|
          pool.flush!
        end
        
        @pools.clear
        self
      end
      
      def [](*args)
        @pools[*args]
      end
    
      class Pool
      
        attr_reader :type, :available, :reserved
      
        def initialize(type)
          @type = type
          @mutex = Mutex.new
          @available = []
          @reserved = []
        end
      
        def flush!
          reserved.each do |entry|
            entry.release
          end
        
          available.each do |entry|
            entry.dispose
          end
          
          @available = []
          @reserved = []
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
        
        private
        def synchronize
        end
      end
    end
    
    module ClassMethods
      
      def new(*args)
        unless instance_methods.include?("dispose")
          raise MustImplementDisposeError.new("#{self.name} must implement a `dispose' instance-method.")
        end
        
        # uri = uri.is_a?(String) ? Addressable::URI::parse(uri) : uri
        # DataObjects.const_get(uri.scheme.capitalize)::Connection.acquire(uri)
      end
      
      def pools
        @pools ||= Pools.new(self)
      end
    end
    
  end
  
end