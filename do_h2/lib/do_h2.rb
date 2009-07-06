require 'data_objects'

if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'
  require 'jdbc/h2'     # the JDBC driver, packaged as a gem
  require 'do_h2_ext'   # the Java extension for this DO driver

  # Another way of loading the JDBC Class. This seems to be more reliable
  # than Class.forName() within the data_objects.Connection Java class,
  # which is currently not working as expected.
  import 'org.h2.Driver'

  module DataObjects
    module H2
      class Connection
        def self.pool_size
          20
        end
      end
    end
  end

else
  warn "do_h2 is only for use with JRuby"
end
