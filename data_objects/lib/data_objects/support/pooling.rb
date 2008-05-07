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
    
      end
    end
    
    module ClassMethods
      
      def new(*args)
        unless instance_methods.include?("dispose")
          raise MustImplementDisposeError.new("#{self.name} must implement a `dispose' instance-method.")
        end
      end
      
      def pools
        @pools ||= Pools.new(self)
      end
    end
    
  end
  
end