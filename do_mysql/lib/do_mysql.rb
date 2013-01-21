require 'data_objects'
if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'

  module DataObjects
    module Mysql
      JDBC_DRIVER = 'com.mysql.jdbc.Driver'
    end
  end

  begin
    java.lang.Thread.currentThread.getContextClassLoader().loadClass(DataObjects::Mysql::JDBC_DRIVER, true)
  rescue java.lang.ClassNotFoundException
    require 'jdbc/mysql' # the JDBC driver, packaged as a gem
    Jdbc::MySQL.load_driver if Jdbc::MySQL.respond_to?(:load_driver)
  end

  # Another way of loading the JDBC Class. This seems to be more reliable
  # than Class.forName() or
  # Thread.currentThread.getContextClassLoader().loadClass() within the
  # data_objects.Connection Java class, which is currently not working as
  # expected.
  java_import DataObjects::Mysql::JDBC_DRIVER

end

begin
  require 'do_mysql/do_mysql'
rescue LoadError
  if RUBY_PLATFORM =~ /mingw|mswin/
    RUBY_VERSION =~ /(\d+.\d+)/
    require "do_mysql/#{$1}/do_mysql"
  else
    raise
  end
end

require 'do_mysql/version'
require 'do_mysql/transaction' if RUBY_PLATFORM !~ /java/
require 'do_mysql/encoding'

if RUBY_PLATFORM =~ /java/

  DataObjects::Mysql::Connection.class_eval do

    def using_socket?
      @using_socket
    end

    def secure?
      false
    end

  end

else

  module DataObjects
    module Mysql
      class Connection
        def secure?
          !(@ssl_cipher.nil? || @ssl_cipher.empty?)
        end
      end
    end
  end

end
