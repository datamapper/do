require 'data_objects'
if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'
  require 'do_jdbc/sqlserver'   # the JDBC driver, packaged as a gem
else # MRI and Ruby 1.9
  # - to be implemented
  warn "do_sqlserver is currently only available for JRuby"
end

require 'do_sqlserver_ext'
require File.expand_path(File.join(File.dirname(__FILE__), 'do_sqlserver', 'version'))
if RUBY_PLATFORM !~ /java/
  # JDBC driver has transactions implementation in Java
  require File.expand_path(File.join(File.dirname(__FILE__), 'do_sqlserver', 'transaction'))
end

if RUBY_PLATFORM !~ /java/
  # MRI / Ruby 1.9 / IronRuby - to be implemented
end

if RUBY_PLATFORM =~ /java/
  # Register SqlServer JDBC driver
  java.sql.DriverManager.registerDriver Java::net.sourceforge.jtds.jdbc.Driver.new

  module DataObjects
    module SqlServer
      class Connection
        def self.pool_size
          20
        end
      end
    end
  end

end
