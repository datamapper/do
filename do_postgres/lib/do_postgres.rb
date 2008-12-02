require 'rubygems'
gem 'data_objects'    
require 'data_objects'
if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'
  gem 'jdbc-sqlite3'
  require 'jdbc/sqlite3' # the JDBC driver, packaged as a gem
end
require 'do_postgres_ext'
require 'do_postgres/transaction'

if RUBY_PLATFORM =~ /java/
  # Another way of loading the JDBC Class. This seems to be more reliable
  # than Class.forName() within the data_objects.Connection Java class,
  # which is currently not working as expected.
  import 'org.postgresql.Driver'

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
