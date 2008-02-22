require 'rbmysql'
require 'data_objects'

module DataObject
  module Mysql
    QUOTE_STRING = "\""
    QUOTE_COLUMN = "`"
    
    class Connection < DataObject::Connection
      
      attr_accessor :mysql_connection
      
      def initialize(connection_string)        
        @connection_string = connection_string
        opts = connection_string.split(" ")
        opts.each do |opt|
          k, v = opt.split("=")
          raise ArgumentError, "you specified an invalid connection component: #{opt}" unless k && v
          instance_variable_set("@#{k}", v)
        end
      end
      
      def change_database(database_name)
        @dbname = database_name
        @connection_string.gsub(/db_name=[^ ]*/, "db_name=#{database_name}")
      end
      
      def open
        @mysql_connection = RbMysql::Connection.new(@host, @user, @password || '', @dbname, @port || 0, @socket, @flags || 0)
        raise ConnectionFailed, "Unable to connect to database with provided connection string. \n#{Mysql_c.mysql_error(@db)}" unless @mysql_connection
        true
      end
      
      def close
        @mysql_connection.close
      end
      
      def create_command(text)
        Command.new(self, text)
      end

      def begin_transaction
        Transaction.new(self)
      end
      
    end
    
    class Field
      attr_reader :name, :type
      
      def initialize(ptr)
        @name, @type = ptr.name.to_s, ptr.type.to_s
      end
    end

    class Transaction

      attr_reader :connection

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
        @connection.logger.debug(sql)
        @connection.mysql_reader.execute_non_reader(sql)
      end

    end
    
    class Reader < DataObject::Reader
      
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
          
          # @native_fields, @fields = Mysql_c.mysql_c_fetch_field_types(@reader, @field_count), Mysql_c.mysql_c_fetch_field_names(@reader, @field_count)
          # raise UnknownError, "An unknown error has occured while trying to process a MySQL query. There were no fields in the resultset\n#{Mysql_c.mysql_error(db)}" if @native_fields.empty?
          
          @has_rows = !(@row = @mysql_reader.fetch_row).nil?
        end
      end
      
      def set_types(type_array)
        @mysql_reader.set_types type_array
      end
      
      def close
        @mysql_reader.close
      end
      
      def name(col)
        super
        @mysql_reader.field_names[col]
      end
      
      def get_index(name)
        super
        @mysql_reader.field_names.index(name)
      end
      
      def null?(idx)
        super
        @row[idx] == nil
      end
      
      def current_row
        @row
      end
      
      def item(idx)
        super
        @row[idx]
      end
      
      def next
        super
        @row = @mysql_reader.fetch_row
        close if @row.nil?
        @row ? true : nil
      end      
      
      def each
        return unless has_rows?
        
        while(true) do
          yield
          break unless self.next
        end
      end
      
      # protected
      # def native_type(col)
      #   super
      #   TYPES[@native_fields[col].type]
      # end
      
      # def typecast(val, idx)
      #   return nil if val.nil? || val == "NULL"
      #   field = @native_fields[idx]
      #   case TYPES[field]
      #     when "NULL"
      #       nil
      #     when "TINY"
      #       val != "0"
      #     when "BIT"
      #       val.to_i(2)
      #     when "SHORT", "LONG", "INT24", "LONGLONG"
      #       val == '' ? nil : val.to_i
      #     when "DECIMAL", "NEWDECIMAL", "FLOAT", "DOUBLE", "YEAR"
      #       val.to_f
      #     when "TIMESTAMP", "DATETIME"
      #       DateTime.parse(val) rescue nil
      #     when "TIME"
      #       DateTime.parse(val).to_time rescue nil
      #     when "DATE"
      #       Date.parse(val) rescue nil
      #     else
      #       val
      #   end
      # end      
    end
    
    class Command < DataObject::Command
      
      def execute_reader(*args)
        super
        sql = escape_sql(args)
        @connection.logger.debug { sql }
        mysql_reader = @connection.mysql_connection.execute_reader(sql)
        raise QueryError, "Your query failed.\n#{@connection.db.last_error}\n#{@text}" unless mysql_reader
        reader = Reader.new(mysql_reader)

        if block_given?
          result = yield(reader)
          reader.close
          result
        else
          reader
        end
      end
      
      def execute_non_query(*args)
        super
        sql = escape_sql(args)
        @connection.logger.debug { sql }
        result = @connection.db.execute_non_reader(sql)
        raise QueryError, "Your query failed.\n#{@connection.db.last_error}\n#{@text}" unless result
        rows_affected = result.affected_rows
        return ResultData.new(@connection, rows_affected, result.inserted_id)
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
    
  end
end
