require 'ruby-debug'
require 'rubygems'
require 'data_objects'

if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'
  gem 'jdbc-sqlserver'
  require 'jdbc/sqlserver' # the JDBC driver, packaged as a gem
else
  require 'dbi' unless defined?(DBI)
  #require 'core_ext/dbi'           # A hack to work around ODBC millisecond handling in Timestamps
end
require 'bigdecimal'
require 'date'
require 'base64'

require File.expand_path(File.join(File.dirname(__FILE__), 'do_sqlserver', 'version'))

if RUBY_PLATFORM !~ /java/
  module DataObjects
    module Sqlserver
      Mode = begin
          require "ADO"
          :ado
        rescue LoadError => e
          :odbc
        end

      class Connection < DataObjects::Connection
        def initialize uri
          # REVISIT: Allow uri.query to modify this connection's mode?
          #host = uri.host.blank? ? "localhost" : uri.host
          host = uri.host.blank? ? nil : uri.host
          user = uri.user || "sa"
          password = uri.password || ""
          path = uri.path.sub(%r{^/}, '')
          if Mode == :ado
            connection_string = "DBI:ADO:Provider=SQLOLEDB;Data Source=#{host};Initial Catalog=#{path};User ID=#{user};Password=#{password};"
          else
            connection_string = "DBI:ODBC:#{path}"
          end

          begin
            @connection = DBI.connect(connection_string, user, password)
          rescue DBI::DatabaseError => e
            # Place to debug connection failures
            raise
          end

          @encoding = uri.query && uri.query["encoding"] || "utf8"

          set_date_format = create_command("SET DATEFORMAT YMD").execute_non_query
          options_reader = create_command("DBCC USEROPTIONS").execute_reader
          while options_reader.next!
            key, value = *options_reader.values
            value = options_reader.values
            case key
            when "textsize"                     # "64512"
            when "language"                     # "us_english", "select * from master..syslanguages" for info
            when "dateformat"                   # "ymd"
            when "datefirst"                    # "7" = Sunday, first day of the week, change with "SET DATEFIRST"
            when "quoted_identifier"            # "SET"
            when "ansi_null_dflt_on"            # "SET"
            when "ansi_defaults"                # "SET"
            when "ansi_warnings"                # "SET"
            when "ansi_padding"                 # "SET"
            when "ansi_nulls"                   # "SET"
            when "concat_null_yields_null"      # "SET"
            else
            end
          end
        end

        def using_socket?
          # This might be an unnecessary feature dragged from the mysql driver
          raise "Not yet implemented"
        end

        def character_set
          @encoding
        end

        def dispose
          @connection.disconnect
          true
        rescue
          false
        end

        def raw
          @connection
        end
      end

      class Command < DataObjects::Command
        # Theoretically, SCOPE_IDENTIY should be preferred, but there are cases where it returns a stale ID, and I don't know why.
        #IDENTITY_ROWCOUNT_QUERY = 'SELECT SCOPE_IDENTITY(), @@ROWCOUNT'
        IDENTITY_ROWCOUNT_QUERY = 'SELECT @@IDENTITY, @@ROWCOUNT'

        attr_reader :types

        def set_types *t
          @types = t.flatten
        end

        def execute_non_query *args
          DataObjects::Sqlserver.check_params @text, args
          begin
            handle = @connection.raw.execute(@text, *args)
          rescue DBI::DatabaseError => e
            handle = @connection.raw.handle
            handle.finish if handle && handle.respond_to?(:finish) && !handle.finished?
            DataObjects::Sqlserver.raise_db_error(e, @text, args)
          end
          handle.finish if handle && handle.respond_to?(:finish) && !handle.finished?

          # Get the inserted ID and the count of affected rows:
          inserted_id, row_count = nil, nil
          if (handle = @connection.raw.execute(IDENTITY_ROWCOUNT_QUERY))
            row1 = Array(Array(handle)[0])
            inserted_id, row_count = row1[0].to_i, row1[1].to_i
            handle.finish
          end
          Result.new(self, row_count, inserted_id)
        end

        def execute_reader *args
          DataObjects::Sqlserver.check_params @text, args
          begin
            handle = @connection.raw.execute(@text, *args)
          rescue DBI::DatabaseError => e
            handle = @connection.raw.handle
            DataObjects::Sqlserver.raise_db_error(e, @text, args)
            handle.finish if handle && handle.respond_to?(:finish) && !handle.finished?
          rescue
            handle = @connection.raw.handle
            handle.finish if handle && handle.respond_to?(:finish) && !handle.finished?
            raise
          end
          Reader.new(self, handle)
        end
      end

      class Result < DataObjects::Result
      end

      # REVISIT: There is no data type conversion happening here. That will make DataObjects sad.
      class Reader < DataObjects::Reader
        def initialize command, handle
          @command, @handle = command, handle
          return unless @handle

          @fields = handle.column_names

          # REVISIT: Prefetch results like AR's adapter does. ADO is a bit strange about handle lifetimes, don't move this until you can test it.
          @rows = []
          types = @command.types
          if types && types.size != @fields.size
            @handle.finish if @handle && @handle.respond_to?(:finish) && !@handle.finished?
            raise ArgumentError, "Field-count mismatch. Expected #{types.size} fields, but the query yielded #{@fields.size}"
          end
          @handle.each do |row|
            field = -1
            @rows << row.map { |value| field += 1; types ? types[field].new(value) : value }
          end
          @handle.finish if @handle && @handle.respond_to?(:finish) && !@handle.finished?
          @current_row = -1
        end

        def close
          if @handle
            @handle.finish if  @handle.respond_to?(:finish) && !@handle.finished?
            @handle = nil
            true
          else
            false
          end
        end

        def next!
          (@current_row += 1) < @rows.size
        end

        def values
          raise StandardError.new("First row has not been fetched") if @current_row < 0
          raise StandardError.new("Last row has been processed") if @current_row >= @rows.size
          @rows[@current_row]
        end

        def fields
          @fields
        end

        def field_count
          @fields.size
        end

        # REVISIT: This is being deprecated
        def row_count
          @rows.size
        end
      end

    private
      def self.check_params cmd, args
        actual = args.size
        expected = param_count(cmd)
        raise ArgumentError.new("Binding mismatch: #{actual} for #{expected}") if actual != expected
      end

      def self.raise_db_error(e, cmd, args)
        msg = e.to_str
        case msg
        when /Too much parameters/, /No data found/
          #puts "'#{cmd}' (#{args.map{|a| a.inspect}*", "}): #{e.to_str}"
          check_params(cmd, args)
        else
          #puts "'#{cmd}' (#{args.map{|a| a.inspect}*", "}): #{e.to_str}"
          #debugger
        end
        raise
      end

      def self.param_count cmd
        cmd.gsub(/'[^']*'/,'').scan(/\?/).size
      end

    end

  end

else

  # Another way of loading the JDBC Class. This seems to be more reliable
  # than Class.forName() within the data_objects.Connection Java class,
  # which is currently not working as expected.
  import 'com.sqlserver.jdbc.Driver'

  module DataObjects
    module Sqlserver
      class Connection
        def self.pool_size
          20
        end

        def using_socket?
          @using_socket
        end

=begin
        # REVISIT: Does this problem even exist for Sqlserver?
        def character_set
          # JDBC API does not provide an easy way to get the current character set
          reader = self.create_command("SHOW VARIABLES LIKE 'character_set_client'").execute_reader
          reader.next!
          char_set = reader.values[1]
          reader.close
          char_set.downcase
        end
=end

      end
    end
  end

end
