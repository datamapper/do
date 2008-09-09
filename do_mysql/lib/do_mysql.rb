require 'rubygems'
require 'data_objects'
require 'do_mysql_ext'                                # the C/Java extension for this DO driver
require 'do_mysql/transaction'

if RUBY_PLATFORM =~ /java/
  require 'do_jdbc/mysql'   # the JDBC driver, packaged as a gem

  # Another way of loading the JDBC Class. This seems to be more relaible
  # than Class.forName() within the data_objects.Connection Java class,
  # which is currently not working as expected.
  require 'java'
  import 'com.mysql.jdbc.Driver'

  module DataObjects
    module Mysql
      class Connection
        def self.pool_size
          20
        end
      end
    end
  end

end
