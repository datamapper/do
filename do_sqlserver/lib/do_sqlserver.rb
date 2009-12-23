require 'data_objects'
if RUBY_PLATFORM =~ /java/
  require 'do_jdbc'
  require 'java'
  require 'do_jdbc/sqlserver'   # the JDBC driver, packaged as a gem
else # MRI and Ruby 1.9
  require 'dbi' unless defined?(DBI)
  require 'dbd_odbc_patch'      # a monkey patch for DNS-less connections
  #require 'core_ext/dbi'       # a hack to work around ODBC millisecond handling in Timestamps
end

require 'bigdecimal'
require 'date'
require 'base64'
require 'do_sqlserver/do_sqlserver' if RUBY_PLATFORM =~ /java/
require 'do_sqlserver/version'
# JDBC driver has transactions implementation in Java
require 'do_sqlserver/transaction' if RUBY_PLATFORM !~ /java/

if RUBY_PLATFORM !~ /java/
  module DataObjects
    module SqlServer
      Mode = :odbc
#      The ADO mode requires a very old DBI to work with the unmaintained DBI::ADO adapter. Don't enable this unless you fix that.
#      Mode = begin
#          require "ADO"
#          :ado
#        rescue LoadError => e
#          :odbc
#        end

      class Connection < DataObjects::Connection
        def initialize uri
          # REVISIT: Allow uri.query to modify this connection's mode?
          #host = uri.host.blank? ? "localhost" : uri.host
          host = uri.host.blank? ? nil : uri.host
          user = uri.user || "sa"
          password = uri.password || ""
          path = uri.path.sub(%r{^/*}, '')
          port = uri.port || "1433"
          if Mode == :ado
            connection_string = "DBI:ADO:Provider=SQLOLEDB;Data Source=#{host};Initial Catalog=#{path};User ID=#{user};Password=#{password};"
          else
            # FIXME: Cannot get a DNS-less configuration without freetds.conf to
            # connect successfully, i.e.:
            # connection_string = "DBI:ODBC:DRIVER=FreeTDS;SERVER=#{host};DATABASE=#{path};TDS_Version=5.0;Port=#{port}"
            #
            # Currently need to setup a dataserver entry in freetds.conf (if
            # using MacPorts, full path is /opt/local/etc/freetds/freetds.conf):
            #
            # [sqlserver]
            #   host = hostname
            #   port = 1433
            #   instance = SQLEXPRESS
            #   tds version = 8.0
            #
            connection_string = "DBI:ODBC:DRIVER=FreeTDS;SERVERNAME=sqlserver;DATABASE=#{path};"
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
          DataObjects::SqlServer.check_params @text, args
          begin
            handle = @connection.raw.execute(@text, *args)
          rescue DBI::DatabaseError => e
            handle = @connection.raw.handle
            handle.finish if handle && handle.respond_to?(:finish) && !handle.finished?
            DataObjects::SqlServer.raise_db_error(e, @text, args)
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
          DataObjects::SqlServer.check_params @text, args
          massage_limit_and_offset args
          begin
            handle = @connection.raw.execute(@text, *args)
          rescue DBI::DatabaseError => e
            handle = @connection.raw.handle
            DataObjects::SqlServer.raise_db_error(e, @text, args)
            handle.finish if handle && handle.respond_to?(:finish) && !handle.finished?
          rescue
            handle = @connection.raw.handle
            handle.finish if handle && handle.respond_to?(:finish) && !handle.finished?
            raise
          end
          Reader.new(self, handle)
        end

      private
        def massage_limit_and_offset args
          @text.sub!(%r{SELECT (.*) ORDER BY (.*) LIMIT ([?0-9]*)( OFFSET ([?0-9]*))?}) {
            what, order, limit, offset = $1, $2, $3, $5

            # LIMIT and OFFSET will probably be set by args. We need exact values, so must
            # do substitution here, and remove those args from the array. This is made easier
            # because LIMIT and OFFSET are always the last args in the array.
            offset = args.pop if offset == '?'
            limit = args.pop if limit == '?'
            offset = offset.to_i
            limit = limit.to_i

            # Reverse the sort direction of each field in the ORDER BY:
            rev_order = order.split(/, */).map{ |f|
              f =~ /(.*) DESC *$/ ? $1 : f+" DESC"
            }*", "

            "SELECT TOP #{limit} * FROM (SELECT TOP #{offset+limit} #{what} ORDER BY #{rev_order}) ORDER BY #{order}"
          }
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
            @rows << row.map do |value|
              field += 1
              next value unless types
              if (t = types[field]) == Integer
                Integer(value)
              elsif t == Float
                Float(value)
              else
                t.new(value)
              end
            end
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
          e.errstr << " running '#{cmd}'"
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

  # Register SqlServer JDBC driver
  java.sql.DriverManager.registerDriver Java::net.sourceforge.jtds.jdbc.Driver.new

  DataObjects::SqlServer::Connection.class_eval do

    def quote_boolean(value)
      value ? 1 : 0
    end

  end

end
