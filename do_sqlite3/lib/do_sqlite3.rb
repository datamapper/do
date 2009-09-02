require 'data_objects'
if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'

  driver =  'org.sqlite.JDBC'
  begin
    java.lang.Thread.currentThread.getContextClassLoader().loadClass(driver, true)
  rescue
    require 'jdbc/sqlite3' # the JDBC driver, packaged as a gem
  end

  # Another way of loading the JDBC Class. This seems to be more reliable
  # than Class.forName() or
  # Thread.currentThread.getContextClassLoader().loadClass() within the
  # data_objects.Connection Java class, which is currently not working as
  # expected.
  java_import driver
end

require 'do_sqlite3_ext'
require 'do_sqlite3/version'
require 'do_sqlite3/transaction'

if RUBY_PLATFORM =~ /java/

  module DataObjects
    module Sqlite3
      class Connection
        def self.pool_size
          # sqlite3 can have only one write access at a time, with this
          # concurrent write access will result in "Database locked" errors
          1
        end
      end
    end
  end

end
