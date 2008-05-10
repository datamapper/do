require 'set'

class Object
  # ==== Notes
  # Provides pooling support to class it got included in.
  #
  # Pooling of objects is a faster way of aquiring instances
  # of objects compared to regular allocation and initialization
  # because it happens once on pool initialization and then
  # objects are just reset on releasing, so getting an instance
  # of pooled object is as performance efficient as getting
  # and object from hash.
  #
  # In Data Objects connections are pooled so that it is
  # unnecessary to allocate and initialize connection object
  # each time connection is needed, like per request in a
  # web application.
  #
  # Pool obviously has to be thread safe because state of
  # object is reset when it is released.
  module Pooling
    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      # ==== Notes
      # Initializes the pool and returns it.
      #
      # ==== Parameters
      # size_limit<Fixnum>:: maximum size of the pool.
      #
      # ==== Returns
      # <ResourcePool>:: initialized pool
      def initialize_pool(size_limit)
        @__pool = ResourcePool.new(size_limit, self)
      end

      def pool
        @__pool
      end
    end

    # ==== Notes
    # Raised when pooled resource class does not
    # implement +dispose+ instance method.
    class DoesNotRespondToDispose < ArgumentError
      def initialize(klass)
        super "Class #{klass.inspect} must implement dispose instance method to be poolable."
      end
    end

    # ==== Notes
    # Pool
    #
    class ResourcePool
      attr_reader :size_limit, :size, :reserved, :available, :class_of_resources

      # ==== Notes
      # Initializes resource pool.
      #
      # ==== Parameters
      # size_limit<Fixnum>:: maximum number of resources in the pool.
      # class_of_resources<Class>:: class of resource.
      #
      # ==== Raises
      # ArgumentError:: when class of resource does not implement
      #                 dispose instance method or is not a Class.
      def initialize(size_limit, class_of_resources)
        raise ArgumentError.new("Expected class of resources to be instance of Class") unless class_of_resources.is_a?(Class)
        raise ArgumentError.new("Class #{class_of_resources} must implement dispose instance method to be poolable.") unless class_of_resources.instance_methods.include?("dispose")

        @size_limit         = size_limit
        @class_of_resources = class_of_resources

        @reserved  = Set.new
        @available = []
        @lock      = Mutex.new
      end

      # ==== Notes
      # Current size of pool: number of already reserved
      # resources.
      def size
        reserved.size
      end

      # ==== Notes
      # Indicates if pool has resources to aquire.
      #
      # ==== Returns
      # <Boolean>:: true if pool has resources can be aquired,
      #             false otherwise.
      def available?
        reserved.size < size_limit
      end

      # ==== Notes
      # Aquires last used available resource and returns it.
      # If no resources available, current implementation
      # throws an exception.
      def aquire
        if available?
          instance = nil
          @lock.synchronize do
            instance = prepair_available_resource

            reserved << instance
          end

          instance
        else
          raise RuntimeError
        end
      end

      # ==== Notes
      # Releases previously aquired instance.
      #
      # ==== Parameters
      # instance <Anything>:: previosly aquired instance.
      #
      # ==== Raises
      # RuntimeError:: when given not pooled instance.
      def release(instance)
        if reserved.include?(instance)
          reserved.delete(instance)
          instance.dispose
          available << instance
        else
          raise RuntimeError
        end
      end

      # ==== Notes
      # Releases all objects in the pool.
      #
      # ==== Returns
      # nil
      def flush!
        @lock.synchronize do
          reserved.each do |instance|
            self.release(instance)
          end
        end
      end

      protected

      # ==== Notes
      # Either allocates new resource,
      # or takes last used available resource from
      # the pool.
      def prepair_available_resource
        if @available.size > 0
          @available.pop
        else
          res = @class_of_resources.allocate
          res.send(:initialize)

          res
        end
      end
    end # ResourcePool
  end
end
