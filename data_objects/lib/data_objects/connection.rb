begin
  require 'fastthread'
rescue LoadError
end

module DataObjects
  # An abstract connection to a DataObjects resource. The physical connection may be broken and re-established from time to time.
  class Connection

    # Make a connection to the database using the DataObjects::URI given.
    # Note that the physical connection may be delayed until the first command is issued, so success here doesn't necessarily mean you can connect.
    def self.new(uri_s)
      uri = DataObjects::URI::parse(uri_s)

      case uri.scheme.to_sym
      when :java
        warn 'JNDI URLs (connection strings) are only for use with JRuby' unless RUBY_PLATFORM =~ /java/
        driver_name = uri.query.delete("scheme")
        conn_uri = uri.to_s.gsub(/\?$/, '')
      when :jdbc
        warn 'JDBC URLs (connection strings) are only for use with JRuby' unless RUBY_PLATFORM =~ /java/

        path = uri.path.sub(/jdbc:/, '')
        driver_name = if path.split(':').first == 'sqlite'
          'sqlite3'
        elsif path.split(':').first == 'postgresql'
          'postgres'
        else
          path.split(':').first
        end

        conn_uri = uri_s # NOTE: for now, do not reformat this JDBC connection
                         # string -- or, in other words, do not let
                         # DataObjects::URI#to_s be called -- as it is not
                         # correctly handling JDBC URLs, and in doing so, causing
                         # java.sql.DriverManager.getConnection to throw a
                         # 'No suitable driver found for...' exception.
      else
        driver_name = uri.scheme
        conn_uri = uri
      end

      # Exceptions to how a driver class is determined for a given URI
      driver_class = if driver_name == 'sqlserver'
        'SqlServer'
      else
        driver_name.capitalize
      end

      clazz = DataObjects.const_get(driver_class)::Connection
      unless clazz.method_defined? :close
        if (uri.scheme.to_sym == :java)
          clazz.class_eval do
            alias close dispose
          end
        else
          clazz.class_eval do
            include Pooling
            alias close release
          end
        end
      end
      clazz.new(conn_uri)
    end

    # Ensure that all Connection subclasses handle pooling and logging uniformly.
    # See also DataObjects::Pooling and DataObjects::Logger
    def self.inherited(target)
      target.class_eval do

        # Allocate a Connection object from the pool, creating one if necessary. This method is active in Connection subclasses only.
        def self.new(*args)
          instance = allocate
          instance.send(:initialize, *args)
          instance
        end

        include Quoting
      end

      if driver_module_name = target.name.split('::')[-2]
        driver_module = DataObjects::const_get(driver_module_name)
        driver_module.class_eval <<-EOS, __FILE__, __LINE__
          def self.logger
            @logger
          end

          def self.logger=(logger)
            @logger = logger
          end
        EOS

        driver_module.logger = DataObjects::Logger.new(nil, :off)
      end
    end

    #####################################################
    # Standard API Definition
    #####################################################

    # Show the URI for this connection
    def to_s
      @uri.to_s
    end

    def initialize(uri) #:nodoc:
      raise NotImplementedError.new
    end

    def dispose #:nodoc:
      raise NotImplementedError.new
    end

    # Create a Command object of the right subclass using the given text
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
