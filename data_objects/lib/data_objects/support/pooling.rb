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
      def initialize_pool(size_limit)
        @__pool = ResourcePool.new(size_limit, self)
      end

      def pool
        @__pool
      end
    end

    class DoesNotRespondToDispose < ArgumentError
      def initialize(klass)
        super "Class #{klass} must implement dispose instance method to be poolable."
      end
    end

    class ResourcePool
      attr_reader :size_limit, :size, :reserved, :available, :class_of_resources

      def initialize(size_limit, class_of_resources)
        raise ArgumentError.new("Expected class of resources to be instance of Class") unless class_of_resources.is_a?(Class)
        raise ArgumentError.new("Class #{class_of_resources} must implement dispose instance method to be poolable.") unless class_of_resources.instance_methods.include?("dispose")

        @size_limit         = size_limit
        @class_of_resources = class_of_resources

        @reserved  = Set.new
        # how come Set has no pop method? Purists!
        @available = []

        @lock = Mutex.new

        @lock.synchronize do
          @size_limit.times do |n|
            instance = class_of_resources.allocate
            instance.send(:initialize)

            @available << instance
          end
        end
      end

      def size
        reserved.size
      end

      def available?
        reserved.size < size_limit
      end

      def aquire
        if available?
          instance = nil
          @lock.synchronize do
            instance = @available.pop

            reserved << instance
          end

          instance
        else
          raise RuntimeError
        end
      end

      def release(instance)
        if reserved.include?(instance)
          reserved.delete(instance)
          instance.dispose
          available << instance
        else
          raise RuntimeError
        end
      end

      def flush!
        @lock.synchronize do
          reserved.each do |instance|
            self.release(instance)
          end
        end
      end
    end # ResourcePool

    class ResourcePoolWithEnvironment < ResourcePool
      attr_reader :class_of_environment

      def initialize(size_limit, class_of_resources, env_class)
        super(size_limit, class_of_resources)
        raise ArgumentError.new("Class #{class_of_resources} must implement aquire and release instance methods to be usable as resource environment.") unless valid_environment_class?(env_class)

        @class_of_environment = env_class
      end

      protected

      def valid_environment_class?(klass)
        instance_methods_list = klass.instance_methods

        instance_methods_list.include?("aquire") && instance_methods_list.include?("release")
      end
    end # ResourcePoolWithEnvironment
  end
end
