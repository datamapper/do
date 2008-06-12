require 'rubygems'
require 'data_objects'

module DataObjects
  module Derby
    JDBC_DRIVER_VERSION = '10.4.1.3'
  end
end

if RUBY_PLATFORM =~ /java/
  require 'do_jdbc-support'
  require 'do_derby_ext'
  require 'java'
  require "derby-#{DataObjects::Derby::JDBC_DRIVER_VERSION}.jar"

  # Another way of loading the JDBC Class. This seems to be more relaible
  # than Class.forName() within the data_objects.Connection Java class,
  # which is currently not working as expected.
  import 'org.apache.derby.jdbc.EmbeddedDriver'
  
  module DataObjects
    module Derby
      class Connection
        def self.pool_size
          20
        end
      end
    end
  end
  
else
  warn "do-derby is only for use with JRuby"
end
