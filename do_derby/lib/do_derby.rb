require 'data_objects'

if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'

  module DataObjects
    module Derby
      JDBC_DRIVER = 'org.apache.derby.jdbc.EmbeddedDriver'
    end
  end

  begin
    java.lang.Thread.currentThread.getContextClassLoader().loadClass(DataObjects::Derby::JDBC_DRIVER, true)
  rescue java.lang.ClassNotFoundException
    require 'jdbc/derby'      # the JDBC driver, packaged as a gem
  end

  require 'do_derby/do_derby'    # the Java extension for this DO driver

  # Another way of loading the JDBC Class. This seems to be more reliable
  # than Class.forName() within the data_objects.Connection Java class,
  # which is currently not working as expected.
  java_import DataObjects::Derby::JDBC_DRIVER

else
  warn "do_derby is only for use with JRuby"
end
