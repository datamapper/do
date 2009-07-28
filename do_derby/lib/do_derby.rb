require 'rubygems'
require 'data_objects'

if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'

  driver = 'org.apache.derby.jdbc.EmbeddedDriver'
  begin
    java.lang.Thread.currentThread.getContextClassLoader().loadClass(driver, true)
  rescue
    require 'jdbc/derby'      # the JDBC driver, packaged as a gem
  end

  require 'do_derby_ext'    # the Java extension for this DO driver

  # Another way of loading the JDBC Class. This seems to be more reliable
  # than Class.forName() within the data_objects.Connection Java class,
  # which is currently not working as expected.
  import driver

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
  warn "do_derby is only for use with JRuby"
end
