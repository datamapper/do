require 'rubygems'
require 'data_objects'
if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'
  # gem 'jdbc-mysql'
  # require 'jdbc/mysql' # the JDBC driver, packaged as a gem
end

require 'do_oracle_ext'
require File.expand_path(File.join(File.dirname(__FILE__), 'do_oracle', 'version'))
# require File.expand_path(File.join(File.dirname(__FILE__), 'do_oracle', 'transaction'))

if RUBY_PLATFORM !~ /java/
  module DataObjects
    module Oracle
      class Connection
        private
        
        # Replace ? placeholders with :n argument placeholders in string of SQL
        # as required by OCI8#exec method
        # Compare number of ? placeholders with number of passed arguments
        # and raise exception if different
        def self.replace_argument_placeholders(sql_string, args_count)
          sql = sql_string

          replacements = 0
          mismatch     = false

          sql.gsub!(/\?/) do |x|
            replacements += 1
            ":#{replacements}"
          end

          if args_count != replacements
            raise ArgumentError, "Binding mismatch: #{args_count} for #{replacements}"
          else
            sql
          end
          
        end
      end
    end
  end
end

# if RUBY_PLATFORM =~ /java/
#   # Another way of loading the JDBC Class. This seems to be more reliable
#   # than Class.forName() within the data_objects.Connection Java class,
#   # which is currently not working as expected.
#   import 'com.mysql.jdbc.Driver'
# 
#   module DataObjects
#     module Mysql
#       class Connection
#         def self.pool_size
#           20
#         end
# 
#         def using_socket?
#           @using_socket
#         end
# 
#         def character_set
#           # JDBC API does not provide an easy way to get the current character set
#           reader = self.create_command("SHOW VARIABLES LIKE 'character_set_client'").execute_reader
#           reader.next!
#           char_set = reader.values[1]
#           reader.close
#           char_set.downcase
#         end
# 
#       end
#     end
#   end
# 
# end
