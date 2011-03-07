require 'data_objects'
if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'

else # MRI and Ruby 1.9
  require 'oci8'
end

begin
  require 'do_oracle/do_oracle'
rescue LoadError
  if RUBY_PLATFORM =~ /mingw|mswin/ then
    RUBY_VERSION =~ /(\d+.\d+)/
    require "do_oracle/#{$1}/do_oracle"
  else
    raise
  end
end

require 'do_oracle/version'

if RUBY_PLATFORM =~ /java/
  # Oracle JDBC driver (ojdbc14.jar or ojdbc5.jar) file should be in JRUBY_HOME/lib or should be in Java class path
  # Register Oracle JDBC driver
  begin
    java.sql.DriverManager.registerDriver Java::oracle.jdbc.OracleDriver.new
  rescue NameError => e
    raise LoadError, "Cannot load Oracle JDBC driver, put it (ojdbc14.jar or ojdbc5.jar) in JRUBY_HOME/lib or in the java extension directory or include in Java class path or call jruby with the option -J-Djava.ext.dirs=/path/to/directory/with/oracle/jars"
  end
  # JDBC driver has transactions implementation in Java

else # MRI and Ruby 1.9
  require 'do_oracle/transaction'
end

if RUBY_PLATFORM !~ /java/
  module DataObjects
    module Oracle
      class Command
        private

        def execute(*args)
          sql, bind_variables = replace_argument_placeholders(@text, args)
          execute_internal(@connection, sql, bind_variables)
        rescue OCIError => e
          raise SQLError.new(e.message, e.code, nil, e.sql, @connection.to_s)
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

          sql.gsub!(/'[^']*'|"[^"]*"|(IS |IS NOT )?\?/) do |x|
            next x unless x =~ /\?$/
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
        def self.oci8_new(user, password, connect_string)
          OCI8.new(user, password, connect_string)
        rescue OCIError => e
          raise ConnectionError.new(e.message, e.code, nil, nil, @connection.to_s)
        end

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
