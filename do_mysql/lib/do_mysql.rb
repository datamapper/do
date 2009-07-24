require 'data_objects'
if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'
  require 'jdbc/mysql' # the JDBC driver, packaged as a gem
end

require 'do_mysql_ext'
require File.expand_path(File.join(File.dirname(__FILE__), 'do_mysql', 'version'))
require File.expand_path(File.join(File.dirname(__FILE__), 'do_mysql', 'transaction'))
require File.expand_path(File.join(File.dirname(__FILE__), 'do_mysql', 'encoding'))

if RUBY_PLATFORM =~ /java/
  # Another way of loading the JDBC Class. This seems to be more reliable
  # than Class.forName() within the data_objects.Connection Java class,
  # which is currently not working as expected.
  import 'com.mysql.jdbc.Driver'

  module DataObjects
    module Mysql
      class Connection
        def self.pool_size
          20
        end

        def using_socket?
          @using_socket
        end

        def secure?
          false
        end
      end
    end
  end

end
