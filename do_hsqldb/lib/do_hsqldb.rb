require 'data_objects'

if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'

  driver = 'org.hsqldb.jdbcDriver'
  begin
    java.lang.Thread.currentThread.getContextClassLoader().loadClass(driver, true)
  rescue
    require 'jdbc/hsqldb'     # the JDBC driver, packaged as a gem
  end
  require 'do_hsqldb/do_hsqldb'   # the Java extension for this DO driver

  # Another way of loading the JDBC Class. This seems to be more reliable
  # than Class.forName() within the data_objects.Connection Java class,
  # which is currently not working as expected.
  java_import(driver) { 'JdbcDriver' }

else
  warn "do_hsqldb is only for use with JRuby"
end
