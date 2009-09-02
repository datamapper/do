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

require 'do_postgres_ext'
require 'do_postgres/version'
require 'do_postgres/transaction'
require 'do_postgres/encoding'

if RUBY_PLATFORM =~ /java/

  module DataObjects
    module Postgres
      class Connection
        def self.pool_size
          20
        end
      end
    end
  end

end
