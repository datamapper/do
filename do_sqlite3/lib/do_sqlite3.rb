require 'data_objects'
if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'
  require 'jdbc/sqlite3' # the JDBC driver, packaged as a gem
end

require 'do_sqlite3_ext'

require File.expand_path(File.join(File.dirname(__FILE__), 'do_sqlite3', 'version'))
require File.expand_path(File.join(File.dirname(__FILE__), 'do_sqlite3', 'transaction'))

if RUBY_PLATFORM =~ /java/
  # Another way of loading the JDBC Class. This seems to be more reliable
  # than Class.forName() within the data_objects.Connection Java class,
  # which is currently not working as expected.
  import 'org.sqlite.JDBC'

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
