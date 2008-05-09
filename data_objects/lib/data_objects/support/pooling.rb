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
    # Raised when pool does not implement disposal method.
    #
    # Each pool must implement dispose method so that
    # aquired resources can be released.
    class MustImplementDisposeError < StandardError
    end

    def self.included(target)
      target.extend(ClassMethods)
    end

    # ==== Notes
    # Releases pool collection.
    #
    # ----
    # @public
    def release
      @__pool.release(self)
    end

    # Pools collection hosts named Pool instances with
    # similar attributes: namely type of objects
    # pooled and max size of the pool.
    #
    # Each pool must implement dispose instance
    # method so that instances are safely released
    # and disposed.
    class Pools
      # Type of objects in pools in the collection.
      attr_reader :type
      # Maximum number of items allowed in pools in the collection.
      attr_accessor :size

      # ==== Notes
      # Initializes pools. Pools are named and stored in a Hash.
      #
      # ==== Parameters
      # type<Class>:: Type of objects in pool.
      # size<Integer>:: size of pool, is optional, default is 4.
      #
      # ----
      # @public
      def initialize(type, size = 4)
        @type = type
        @size = size
        @pools = Hash.new { |h,k| h[k] = Pool.new(@size, @type, k) }
      end

      # ==== Notes
      # Flushes and clears all pools.
      #
      # ==== Returns
      # <Pools>:: self is returned so calls can be chained.
      #
      # ==== Examples
      # Thing::pools.flush!
      #
      # Flushes all pools at once.
      # ----
      # @public
      def flush!
        @pools.each_pair do |args,pool|
          pool.flush!
        end

        @pools.clear
        self
      end

      # ==== Notes
      # Returns pool(s) by name. Delegates to underlying
      # pools storage implmented as a Hash.
      #
      # ==== Returns
      # <Array>:: Pools with given names.
      #
      # ----
      # @public
      def [](*args)
        @pools[*args]
      end

      # ==== Notes
      # Pool is a tuple of objects (a limited collection) that
      # can be aquired and released as needed. When application
      # exits, pool is disposed.
      #
      class Pool
        # type<Class>:: type of objectes in this pool.
        # available<Array>:: pooled objects that are free to be aquired.
        # reserved<Set>:: pooled objects that are already in use.
        attr_reader :type, :available, :reserved, :size

        # ==== Notes
        # Initializes the pool by clearing available and reserved sets,
        # initializing a mutex that provides thread safe pool operations
        # and stores pool size and pooled objects type.
        #
        # ==== Parameters
        # size<Integer>:: maximum number of objects pool can store.
        # type<Class>:: class of instances in this pool.
        # initializer<~to_a>:: arguments passed to pool object
        #                      class on instantiation of new object.
        #
        # ----
        # @public
        def initialize(size, type, initializer)
          @size = size
          @type = type
          @initializer = initializer
          @lock = Mutex.new
          # FIXME: use Set for consistency.
          @available = []
          @reserved = Set.new
        end

        # ==== Notes
        # Releases all reserved objects in the pool
        # and makes them available, then disposes
        # all objects in the pool and clears it.
        #
        # This method is thread safe.
        #
        # ----
        # @public
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

            # FIXME: highly recommended to use Set for both
            # so that people are never get confused.
            @available = []
            @reserved = Set.new
          end
        end

        # ==== Notes
        # Initializes new pool for the class Pooling module included in.
        #
        # ==== Returns
        # New initialized pool.
        #
        # ----
        # @public
        def new
          if @available.empty?
            @lock.synchronize do
              instance = nil

              # FIXME: flog score is too high,
              # a lot of code duplication but first
              # need to figure out why so.
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

        # ==== Notes
        # Releases the pool and makes all slots in it available in a
        # thread safe manner.
        #
        # ==== Parameters
        # instance<Pool>:: pool to release.
        #
        # ==== Returns
        # nil
        #
        # ----
        # @public
        def release(instance)
          @lock.synchronize do
            if @reserved.delete?(instance)
              @available << instance
            end
          end
          return nil
        end

        private

        # ==== Notes
        # Aquires instance from pool in a thread safe manner,
        # places it into reserved instances set then returns it.
        #
        # ==== Returns
        # <Pool>:: new instance aquired from pool.
        #
        # ----
        # @public
        def aquire_instance!
          instance = nil

          @lock.synchronize do
            instance = @available.pop
            raise StandardError.new("Synchronization error on instance aquire: #{self.inspect}.") unless instance
            @reserved << instance
          end

          instance
        end
      end
    end

    module ClassMethods
      # ==== Notes
      # Creates new pooled object in the pool by name.
      #
      # ==== Parameters
      # <*args>:: name(s) of pools in this pool collection.
      #
      # ==== Examples
      # bob = Thing.new("bob")
      # bob.name.should == 'bob'
      #
      # This aquires one object in pool with name "bob".
      # ----
      # @public
      def new(*args)
        unless instance_methods.include?("dispose")
          raise MustImplementDisposeError.new("#{self.name} must implement a `dispose' instance-method.")
        end

        pools[*args].new
      end

      # ==== Notes
      # Returns pools collection,
      # does initialization of it when necessary.
      #
      # ==== Returns
      # <Pools>:: Pool collection.
      #
      # --
      # @public
      def pools
        @pools ||= Pools.new(self)
      end
    end
  end
end
