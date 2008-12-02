require 'rubygems'
require 'data_objects'
require 'do_postgres_ext'
require 'do_postgres/transaction'

if RUBY_PLATFORM =~ /java/
  require 'do_jdbc/postgres'   # the JDBC driver, packaged as a gem

  # Another way of loading the JDBC Class. This seems to be more relaible
  # than Class.forName() within the data_objects.Connection Java class,
  # which is currently not working as expected.
  require 'java'
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
