require 'data_objects'

if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'

  module DataObjects
    module H2
      JDBC_DRIVER = 'org.h2.Driver'
    end
  end

  begin
    java.lang.Thread.currentThread.getContextClassLoader().loadClass(DataObjects::H2::JDBC_DRIVER, true)
  rescue java.lang.ClassNotFoundException
    require 'jdbc/h2'     # the JDBC driver, packaged as a gem
  end

  require 'do_h2/do_h2'   # the Java extension for this DO driver

  # Another way of loading the JDBC Class. This seems to be more reliable
  # than Class.forName() within the data_objects.Connection Java class,
  # which is currently not working as expected.
  java_import DataObjects::H2::JDBC_DRIVER

else
  warn "do_h2 is only for use with JRuby"
end
