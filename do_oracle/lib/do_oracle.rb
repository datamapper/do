require 'rubygems'
require 'data_objects'
if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'
  # gem 'jdbc-mysql'
  # require 'jdbc/mysql' # the JDBC driver, packaged as a gem

else # MRI and Ruby 1.9
  gem 'ruby-oci8', '>=2.0.2'
  require 'oci8'
  require File.expand_path(File.join(File.dirname(__FILE__), 'oci8_patch'))
end

require 'do_oracle_ext'
require File.expand_path(File.join(File.dirname(__FILE__), 'do_oracle', 'version'))
# require File.expand_path(File.join(File.dirname(__FILE__), 'do_oracle', 'transaction'))

if RUBY_PLATFORM !~ /java/
  module DataObjects
    module Oracle
      class Command
        private
        
        def execute(*args)
          oci8_conn = @connection.instance_variable_get("@connection")
          raise OracleError, "This connection has already been closed." unless oci8_conn
          
          sql, bind_variables = replace_argument_placeholders(@text, args)
          execute_internal(oci8_conn, sql, bind_variables)
        end
        
        # Replace ? placeholders with :n argument placeholders in string of SQL
        # as required by OCI8#exec method
        # Compare number of ? placeholders with number of passed arguments
        # and raise exception if different
        def replace_argument_placeholders(sql_string, args)
          sql = sql_string.dup
          args_count = args.length
          bind_variables = []
          
          replacements = 0
          mismatch     = false
          
          sql.gsub!(/\?/) do |x|
            arg = args[replacements]
            replacements += 1
            case arg
            when Array
              i = 0
              "(" << arg.map do |a|
                bind_variables << a
                i += 1
                ":a#{replacements}_#{i}"
              end.join(", ") << ")"
            when Range
              bind_variables << arg.first << arg.last
              ":r#{replacements}_1 AND :r#{replacements}_2"
            else
              bind_variables << arg
              ":#{replacements}"
            end
          end
          
          if sql =~ /^\s*INSERT.+RETURNING.+INTO :insert_id\s*$/i
            @insert_id_present = true
          end
          
          if args_count != replacements
            raise ArgumentError, "Binding mismatch: #{args_count} for #{replacements}"
          else
            [sql, bind_variables]
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
