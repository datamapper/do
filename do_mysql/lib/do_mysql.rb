require 'rubygems'
gem 'data_objects'    
require 'data_objects'
if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'
  gem 'jdbc-mysql'
  require 'jdbc/mysql' # the JDBC driver, packaged as a gem
end
require 'do_mysql_ext' # the C/Java extension for this DO driver
require 'do_mysql' / 'transaction'

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
      end
    end
  end

end
