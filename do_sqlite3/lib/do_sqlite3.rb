require 'sqlite3_c'
require 'data_objects'

module DataObject
  module Sqlite3
    
    QUOTE_STRING = "\""
    QUOTE_COLUMN = "'"
    
    class Connection < DataObject::Connection
      
      attr_reader :db
      
      def initialize(connection_string)
        @state = STATE_CLOSED        
        @connection_string = connection_string
        @conn = Hash[*connection_string.split(" ").map {|x| x.split("=")}.flatten]["dbname"]
      end

      def open
        r, d = Sqlite3_c.sqlite3_open(@conn)
        unless r == Sqlite3_c::SQLITE_OK
          raise ConnectionFailed, "Unable to connect to database with provided connection string. \n#{Sqlite3_c.sqlite3_errmsg(d)}"
        else
          @db = d
        end
        @state = STATE_OPEN
        true
      end

      def close
        Sqlite3_c.sqlite3_close(@db)
        @state = STATE_CLOSED
        true
      end
      
      def create_command(text)
        Command.new(self, text)
      end
      
    end
    
    class Reader < DataObject::Reader
      
      def initialize(db, reader)
        @reader = reader
        result = Sqlite3_c.sqlite3_step(reader)        
        rows_affected, field_count = Sqlite3_c.sqlite3_changes(db), Sqlite3_c.sqlite3_column_count(reader)
        if field_count == 0
          @records_affected = rows_affected
          close
        else
          @field_count = field_count
          @fields, @field_types = [], []
          i = 0
          while(i < @field_count)
            @field_types.push(Sqlite3_c.sqlite3_column_type(reader, i))
            @fields.push(Sqlite3_c.sqlite3_column_name(reader, i))
            i += 1
          end
          case result
          when Sqlite3_c::SQLITE_BUSY, Sqlite3_c::SQLITE_ERROR, Sqlite3_c::SQLITE_MISUSE
            raise ReaderError, "An error occurred while trying to get the next row\n#{Sqlite3_c.sqlite3_errmsg(db)}"
          else
            @has_rows = result == Sqlite3_c::SQLITE_ROW
            @state = STATE_OPEN
            close unless @has_rows
          end
        end
      end
      
      def real_close
        Sqlite3_c.sqlite3_finalize(@reader)
      end
      
      def name(idx)
        super
        @fields[idx]
      end
      
      def get_index(name)
        super
        @fields.index(name)
      end
      
      def null?(idx)
        super
        item(idx).nil?
      end
      
      def item(idx)
        super
        case @field_types[idx]
        when 1 # SQLITE_INTEGER
          Sqlite3_c.sqlite3_column_int(@reader, idx).to_i
        when 2 # SQLITE_FLOAT
          Sqlite3_c.sqlite3_column_double(@reader, idx)
        else
          Sqlite3_c.sqlite3_column_text(@reader, idx)
        end
      end
      
      def each
        return unless has_rows?
        
        while(true) do
          yield
          break unless Sqlite3_c.sqlite3_step(@reader) == Sqlite3_c::SQLITE_ROW
        end
      end
      
    end
    
    class Command < DataObject::Command
      
      def execute_reader(*args)
        super
        sql = escape_sql(args)
        @connection.logger.debug { sql }
        result, ptr = Sqlite3_c.sqlite3_prepare_v2(@connection.db, sql, sql.size + 1)
        unless result == Sqlite3_c::SQLITE_OK
          raise QueryError, "Your query failed.\n#{Sqlite3_c.sqlite3_errmsg(@connection.db)}\nQUERY: \"#{sql}\""
        else
          reader = Reader.new(@connection.db, ptr)
          
          if block_given?
            return_value = yield(reader)
            reader.close
            return_value
          else
            reader
          end
        end
      end
      
      def execute_non_query(*args)
        super
        sql = escape_sql(args)
        @connection.logger.debug { sql }
        result, reader = Sqlite3_c.sqlite3_prepare_v2(@connection.db, sql, -1)
        unless result == Sqlite3_c::SQLITE_OK
          Sqlite3_c.sqlite3_finalize(reader)
          raise QueryError, "Your query failed.\n#{Sqlite3_c.sqlite3_errmsg(@connection.db)}\nQUERY: \"#{sql}\""
        else
          exec_result = Sqlite3_c.sqlite3_step(reader)
          Sqlite3_c.sqlite3_finalize(reader)
          if exec_result == Sqlite3_c::SQLITE_DONE
            ResultData.new(@connection, Sqlite3_c.sqlite3_changes(@connection.db), Sqlite3_c.sqlite3_last_insert_rowid(@connection.db))
          else
            raise QueryError, "Your query failed or you tried to execute a SELECT query through execute_non_reader\n#{Sqlite3_c.sqlite3_errmsg(@connection.db)}\nQUERY: \"#{@text}\""
          end
        end
      end
      
      def quote_symbol(value)
        value.to_s
      end
      
      def quote_boolean(value)
        value ? '1' : '0'
      end
    end
    
  end
end