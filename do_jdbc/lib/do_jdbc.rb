require 'java'
require 'bigdecimal'
require 'date'

module DataObjects
  module Jdbc
    class Connection < DataObjects::Connection
      include_class 'java.sql.DriverManager'

      def initialize(uri)
        options = Hash[*uri.query.split(/[&=]/)].inject({}) { |h, (k, v)| h[k.to_sym] = v; h }
        url = nil
        url = "//#{uri.host}" if uri.host
        url << ":#{uri.port}" if url && uri.port
        if url
          url << uri.path
        else
          url = uri.path.dup["/"] = ""
        end

        include_class(options[:driver])
        @connection = DriverManager.get_connection("jdbc:#{options[:protocol]}:#{url}", uri.user, uri.password)
      end

      def jdbc_connection
        @connection
      end

      def dispose
        @connection.close
      end

      def begin_transaction

      end
    end

    class Command < DataObjects::Command
      include_class "java.sql.Statement"
      def set_types(types)
        @types = types
      end

      def execute_non_query(*args)
        sql = @connection.jdbc_connection.create_statement
        return nil if (updcount = sql.execute_update(@text)) < 0
        key = "TODO"
        Result.new(self, updcount, key)
        # create a result object with the number of affected rows and the created id, if any
      end

      def execute_reader(*args)
        # escape all parameters given and pass them to query
        # execute the query
        # if no response return nil
        # save the field count
        # instantiate a new reader
               # pass the response to the reader
        # mark the reader as opened
        # save the field_count in reader
        # get the field types
        # if no types passed, guess the types
        # for each field
        #   save its name
        #   guess the type if no types passed
        # set the reader @field_names and @types (guessed or otherwise)
        # yield the reader if a block is given, then close it
        # return the reader

        sql = @connection.jdbc_connection.create_statement()

        Reader.new(sql.execute_query(@text), @types)
      end
    end

    class Result < DataObjects::Result

    end

    class Transaction < DataObjects::Transaction

    end

    class Reader < DataObjects::Reader
      include_class 'java.sql.Types'

      def initialize(result, types)
        @result = result
        @meta_data = result.meta_data
        @types = types || java_types_to_ruby_types(@meta_data)
      end

      def java_types_to_ruby_types(meta_data)
        (1 .. meta_data.column_count).map do |i|
          case meta_data.column_type(i)
          when Types::INTEGER, Types::SMALLINT, Types::TINYINT
            Fixnum
          when Types::BIGINT
            Bignum
           when Types::BIT, Types::BOOLEAN
            TrueClass
          when Types::CHAR, Types::VARCHAR
            String
          when Types::DATE
            Date
          when Types::DECIMAL, Types::NUMERIC
            BigDecimal
          when Types::FLOAT, Types::DOUBLE
            Float
          when Types::TIMESTAMP
            DateTime
          when Types::OTHER
            String
          else
            raise "No casting rule for type #{meta_data.column_type(i)} (#{meta_data.column_name(i)}). Please report this."
          end
        end
      end

      def close

      end

      def next!
        @in_row = (@result.next || nil)
      end

      def values
        raise "error" unless @in_row

        @values = (1 .. @meta_data.column_count).map do |i|
          type_cast_value(i - 1, @result.object(i))
        end
      end

      def type_cast_value(index, value)
        if String == @types[index]
          value.to_s
        elsif [Integer, Fixnum, Bignum].include?(@types[index])
          value.to_i
        elsif BigDecimal == @types[index]
          BigDecimal.new(value.to_string)
        elsif Float == @types[index]
          value.to_f
        elsif [TrueClass, FalseClass].include?(@types[index])
          value
        elsif Date == @types[index]
          Date.parse(value.to_string)
        elsif DateTime == @types[index]
          DateTime.parse(value.to_string)
        else
          raise "Oops! Forgot to handle #{@types[index]} (#{value})"
        end
      end

      def fields
        @fields ||= begin
          ccnt = @meta_data.column_count
          fields = []
          1.upto(ccnt) do |i|
            fields << @meta_data.column_name(i)
          end
          fields
        end
      end
    end
  end
end
