require 'data_objects'
require 'rbmysql'

module DataObjects
  module Mysql
    QUOTE_STRING = "\""
    QUOTE_COLUMN = "`"
    
    class Connection < DataObjects::Connection
      
      protected
      
      def initialize(uri)
        scheme, user_info, host, port, registry, path, opaque, query, fragment = URI.split(uri)
        user, password = user_info.split(':')
        
        @mysql_connection = RbMysql::Connection.new(host, user, password || '', path[1..-1], port || 3306, @socket, @flags || 0)
        raise ConnectionFailed, "Unable to connect to database with provided connection string." unless @mysql_connection
      end
      
      public
      
      # Responsible for closing the underlying RbMysql::Connection
      def real_close
        @mysql_connection.close
      end
      
      def create_command(text)
        Command.new(self, text)
      end

      def begin_transaction
        Transaction.new(self)
      end
      
      def execute_reader(sql)
        mysql_reader = @mysql_connection.execute_reader(sql)
        raise StandardError, "Your query failed.\n#{@mysql_connection.last_error}\n#{@sql}" unless mysql_reader
        Reader.new(mysql_reader)
      end

      def execute_non_query(sql)
        @mysql_connection.execute_non_query(sql)
      end

    end
    
    class Transaction < DataObjects::Transaction

      def initialize(conn)
        @connection = conn
        exec_sql("BEGIN")
      end

      # Commits the transaction
      def commit
        exec_sql("COMMIT")
      end

      # Rolls back the transaction
      def rollback(savepoint = nil)
        raise NotImplementedError, "MySQL does not support savepoints" if savepoint
        exec_sql("ROLLBACK")
      end

      # Creates a savepoint for rolling back later (not commonly supported)
      def save(name)
        raise NotImplementedError, "MySQL does not support savepoints"
      end

      def create_command(*args)
        @connection.create_command(*args)
      end

      protected

      def exec_sql(sql)
        # @connection.logger.debug(sql)
        @connection.mysql_reader.execute_non_reader(sql)
      end

    end
    
    class Command < DataObjects::Command
      
      def execute_reader(*args)
        sql = escape_sql(args)
        # @connection.logger.debug { sql }
        reader = @connection.execute_reader(sql)
        # reader.set_types @field_types

        if block_given?
          result = yield(reader)
          reader.close
          result
        else
          reader
        end        
      end
      
      # def set_types(type_array)
      #   @field_types = type_array
      # end
      
      def execute_non_query(*args)
        super
        sql = escape_sql(args)
        # @connection.logger.debug { sql }
        result = @connection.execute_non_reader(sql)
        raise QueryError, "Your query failed.\n#{@connection.last_error}\n#{@text}" unless result
        rows_affected = result.affected_rows
        return DataObjects::Result.new(@connection, rows_affected, result.inserted_id)
      end
      
      private
      
      def escape_sql(*args)
        query = args.shift
        @text
      end
      
      def quote_time(value)
        # TIMESTAMP() used for both time and datetime columns
        quote_datetime(value)
      end
      
      def quote_datetime(value)
        "TIMESTAMP('#{value.strftime("%Y-%m-%d %H:%M:%S")}')"
      end
      
      def quote_date(value)
        "DATE('#{value.strftime("%Y-%m-%d")}')"
      end
        
    end
    
    class Reader < DataObjects::Reader
      
      def initialize(mysql_reader)
        @mysql_reader = mysql_reader

        unless @mysql_reader
          if mysql_reader.field_count == 0
            @records_affected = mysql_reader.affected_rows
            close
          else
            raise UnknownError, "An unknown error has occured while trying to process a MySQL query.\n#{@mysql_reader.connection.last_error}"
          end
        else
          @field_count = @mysql_reader.field_count

          # Reads the first row. You shouldn't call #next! until you've used #values first!
          @current_row = @mysql_reader.fetch_row
        end
      end
      
      # def set_types(types)
      #   @mysql_reader.set_types(types)
      # end

      def fields
        @mysql_reader.field_names
      end

      def eof?
        @current_row.nil?
      end

      def values
        @current_row
      end

      def close
        @mysql_reader.close
      end

      # Moves the cursor forward.
      def next!
        if @current_row
          @current_row = @mysql_reader.fetch_row
          @current_row ? true : nil
        else
          nil
        end
      end
      
      # def each
      #   return unless has_rows?
      #   
      #   while(true) do
      #     yield
      #     break unless self.next
      #   end
      # end
    end
    
  end
end
