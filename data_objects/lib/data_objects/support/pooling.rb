require 'set'

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
      @__pool.release(self)
    end 
    
    class Pools
      
      attr_reader :type
      
      def initialize(type)
        @type = type
        @pools = Hash.new { |h,k| h[k] = Pool.new(@type, k) }
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
      
        def initialize(type, initializer)
          @type = type
          @initializer = initializer
          @lock = Mutex.new
          @available = []
          @reserved = Set.new
        end
      
        def flush!
          reserved.each do |entry|
            entry.release
          end
        
          available.each do |entry|
            entry.dispose
          end
          
          @available = []
          @reserved = Set.new
        end
        
        def new
          instance = nil

          @lock.synchronize do          
            unless @available.empty?
              instance = @available.pop
            else
              instance = @type.allocate
              instance.send(:initialize, *@initializer)
              at_exit { instance.dispose }
              instance.instance_variable_set("@__pool", self)
            end

            @reserved << instance
          end

          return instance
        end

        def release(instance)
          @lock.synchronize do
            if @reserved.delete?(instance)
              @available << instance
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
        
        pools[*args].new
        # uri = uri.is_a?(String) ? Addressable::URI::parse(uri) : uri
        # DataObjects.const_get(uri.scheme.capitalize)::Connection.acquire(uri)
      end
      
      def pools
        @pools ||= Pools.new(self)
      end
    end
    
  end
  
end