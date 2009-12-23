require 'data_objects'
if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'

  driver = 'org.postgresql.Driver'
  begin
    java.lang.Thread.currentThread.getContextClassLoader().loadClass(driver, true)
  rescue
    require 'jdbc/postgres' # the JDBC driver, packaged as a gem
  end

  # Another way of loading the JDBC Class. This seems to be more reliable
  # than Class.forName() within the data_objects.Connection Java class,
  # which is currently not working as expected.
  java_import driver

end

begin
  require 'do_postgres/do_postgres'
rescue LoadError
  if RUBY_PLATFORM =~ /mingw|mswin/ then
    RUBY_VERSION =~ /(\d+.\d+)/
    require "do_postgres/#{$1}/do_postgres"
  else
    raise
  end
end

require 'do_postgres/version'
require 'do_postgres/transaction' if RUBY_PLATFORM !~ /java/
require 'do_postgres/encoding'
