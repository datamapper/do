require 'data_objects'
if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'

  # ojdbc14.jar file should be in ENV['PATH'] or should be in load path
  # Adds JRuby classloader to current thread classloader - as a result ojdbc14.jar should not be in $JRUBY_HOME/lib
  java.lang.Thread.currentThread.setContextClassLoader(JRuby.runtime.jruby_class_loader)

  ojdbc_jar = "ojdbc14.jar"
  if ojdbc_jar_path = ENV["PATH"].split(/[:;]/).find{|d| File.exists?(File.join(d,ojdbc_jar))}
    require File.join(ojdbc_jar_path,ojdbc_jar)
  else
    require ojdbc_jar
  end

else # MRI and Ruby 1.9
  gem 'ruby-oci8', '>=2.0.2'
  require 'oci8'
  require File.expand_path(File.join(File.dirname(__FILE__), 'oci8_patch'))
end

require 'do_oracle_ext'
require File.expand_path(File.join(File.dirname(__FILE__), 'do_oracle', 'version'))
if RUBY_PLATFORM !~ /java/
  # JDBC driver has transactions implementation in Java
  require File.expand_path(File.join(File.dirname(__FILE__), 'do_oracle', 'transaction'))
end

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

          sql.gsub!(/(IS |IS NOT )?\?/) do |x|
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
            when Regexp
              regexp_options = arg.options & Regexp::IGNORECASE > 0 ? "i" : ""
              regexp_options << "m" if arg.options & Regexp::MULTILINE > 0
              bind_variables << arg.source << regexp_options
              ":re#{replacements}_1, :re#{replacements}_2"
            when NilClass
              # if "IS ?" or "IS NOT ?" then replace with NULL
              if $1
                "#{$1}NULL"
              # otherwise pass as bind variable
              else
                bind_variables << arg
                ":#{replacements}"
              end
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

      class Connection
        # Quote true, false as 1 and 0
        def quote_boolean(value)
          value ? 1 : 0
        end

        # for getting Ruby current time zone in C extension
        def self.ruby_time_zone
          ENV['TZ']
        end
      end

    end
  end
end

if RUBY_PLATFORM =~ /java/
  # Register Oracle JDBC driver
  java.sql.DriverManager.registerDriver Java::oracle.jdbc.driver.OracleDriver.new

  module DataObjects
    module Oracle
      class Connection
        def self.pool_size
          20
        end

      end
    end
  end

end
