require 'set'

class Object

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
    def release
      @__pool.release(self)
    end

    # Pools collection hosts named pools with
    # similar attributes: namely type of objects
    # pooled.
    #
    # Each pool must implement dispose instance
    # method so that itstances are safely released
    # and disposed.
    class Pools
      # Type of pools in the collection
      attr_reader :type
      # Maximum number of items allowed in pools in the collection.
      attr_accessor :size

      # ==== Notes
      # Initializes pools. Pools are stored in a Hash,
      #
      # ==== Parameters
      # type<Class>:: Type of objects in pool.
      # size<Integer>:: size of pool, is optional, default is 4.
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
      def [](*args)
        @pools[*args]
      end

      # ==== Notes
      # Pool is a tuple of objects (a limited collection) that
      # can be aquired and released as needed. When application
      # exits, pool is disposed.
      #
      class Pool
        # type<?>:: ?
        # available<Array>:: pooled objects that are free to be aquired.
        # reserved<Set>:: pooled objects that are already in use.
        attr_reader :type, :available, :reserved

        # ==== Notes
        # Initializes the pool by clearing available and reserved sets,
        # initializing a mutex that provides thread safe pool operations
        # and stores pool size and type.
        #
        # ==== Parameters
        # size<Integer>:: maximum number of objects pool can store.
        # type<Class>:: class of instances in this pool.
        # initializer<~to_a>:: arguments passed to pool object
        #                      class on instantiation of new object.
        def initialize(size, type, initializer)
          @size = size
          @type = type
          @initializer = initializer
          @lock = Mutex.new
          @available = []
          @reserved = Set.new
        end

        # ==== Notes
        # Releases all reserved objects in the pool
        # and makes them available, then disposes
        # all objects in the pool and clears it.
        #
        # This method is thread safe.
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

        # ==== Notes
        # Initializes new pool.
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
        def aquire_instance!
          instance = nil

          @lock.synchronize do
            instance = @available.pop
            raise StandardError.new("Syncronization error on instance aquire: #{self.inspect}") unless instance
            @reserved << instance
          end

          instance
        end
      end
    end

    module ClassMethods
      # ==== Notes
      # Creates new pools in the pools collection.
      #
      # ==== Parameters
      # <*args>:: name(s) of pools in this pool collection.
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
