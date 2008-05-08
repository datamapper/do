require 'set'

class Object
  
  module Pooling
    
    class MustImplementDisposeError < StandardError
    end
    
    def self.included(target)
      target.extend(ClassMethods)
    end
    
    def release
      @__pool.release(self)
    end 
    
    class Pools
      
      attr_reader :type
      attr_accessor :size
      
      def initialize(type, size = 4)
        @type = type
        @size = size
        @pools = Hash.new { |h,k| h[k] = Pool.new(@size, @type, k) }
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
      
        def initialize(size, type, initializer)
          @size = size
          @type = type
          @initializer = initializer
          @lock = Mutex.new
          @available = []
          @reserved = Set.new
        end
      
        def flush!
          @lock.synchronize do
            reserved.each do |instance|
              if @reserved.delete?(instance)
                @available << instance
              end
            end
        
            available.each do |instance|
              instance.dispose
            end
          
            @available = []
            @reserved = Set.new
          end
        end
        
        def new
          if @available.empty?
            @lock.synchronize do
              instance = nil
              
              if @available.empty?
                if @reserved.size < @size
                  instance = @type.allocate
                  instance.send(:initialize, *@initializer)
                  at_exit { instance.dispose }
                  instance.instance_variable_set("@__pool", self)
                else
                  # until(instance) do
                    # TODO: Need to wait for an instance to become available,
                    # but to do that we need to not use a synchronization block.
                  # end
                  
                  instance = @type.allocate
                  instance.send(:initialize, *@initializer)
                  at_exit { instance.dispose }
                  instance.instance_variable_set("@__pool", self)
                end
              else
                instance = @available.pop
              end
              
              @reserved << instance
              instance
            end
          else
            aquire_instance!
          end
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
        def aquire_instance!
          instance = nil
          
          @lock.synchronize do
            instance = @available.pop
            raise StandardError.new("Concurrency Error!") unless instance
            @reserved << instance
          end
          
          instance
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