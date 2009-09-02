require 'data_objects'
if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'

  driver = 'com.mysql.jdbc.Driver'
  begin
    java.lang.Thread.currentThread.getContextClassLoader().loadClass(driver, true)
  rescue
    require 'jdbc/mysql' # the JDBC driver, packaged as a gem
  end

  # Another way of loading the JDBC Class. This seems to be more reliable
  # than Class.forName() or
  # Thread.currentThread.getContextClassLoader().loadClass() within the
  # data_objects.Connection Java class, which is currently not working as
  # expected.
  java_import driver

end

require 'do_mysql_ext'
require 'do_mysql/version'
require 'do_mysql/transaction'
require 'do_mysql/encoding'

if RUBY_PLATFORM =~ /java/

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
