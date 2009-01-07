require 'rubygems'
require 'data_objects'
if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'
  gem 'jdbc-postgres'
  require 'jdbc/postgres' # the JDBC driver, packaged as a gem
end

require 'do_postgres_ext'
require File.expand_path(File.join(File.dirname(__FILE__), 'do_postgres', 'version'))
require File.expand_path(File.join(File.dirname(__FILE__), 'do_postgres', 'transaction'))

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

        def character_set
          # JDBC API does not provide an easy way to get the current character set
          # For now, we code the character_set used as utf8
          "utf8"
        end

      end
    end
  end

end
