module DataObjects
  class Command

    attr_reader :connection

    # initialize creates a new Command object
    def initialize(connection, text)
      raise ArgumentError.new("+connection+ must be a DataObjects::Connection") unless DataObjects::Connection === connection
      @connection, @text = connection, text
    end

    def execute_non_query(*args)
      raise NotImplementedError.new
    end

    def execute_reader(*args)
      raise NotImplementedError.new
    end

    def set_types(column_types)
      raise NotImplementedError.new
    end

    def to_s
      @text
    end

    private

    # Escape a string of SQL with a set of arguments.
    # The first argument is assumed to be the SQL to escape,
    # the remaining arguments (if any) are assumed to be
    # values to escape and interpolate.
    #
    # ==== Examples
    #   escape_sql("SELECT * FROM zoos")
    #   # => "SELECT * FROM zoos"
    #
    #   escape_sql("SELECT * FROM zoos WHERE name = ?", "Dallas")
    #   # => "SELECT * FROM zoos WHERE name = `Dallas`"
    #
    #   escape_sql("SELECT * FROM zoos WHERE name = ? AND acreage > ?", "Dallas", 40)
    #   # => "SELECT * FROM zoos WHERE name = `Dallas` AND acreage > 40"
    #
    # ==== Warning
    # This method is meant mostly for adapters that don't support
    # bind-parameters.
    def escape_sql(args)
      sql = @text.dup
      vars = args.dup

      replacements = 0
      mismatch     = false

      sql.gsub!(/\?/) do |x|
        replacements += 1
        if vars.empty?
          mismatch = true
        else
          var = vars.shift
          connection.quote_value(var)
        end
      end

      if !vars.empty? || mismatch
        raise ArgumentError, "Binding mismatch: #{args.size} for #{replacements}"
      else
        sql
      end
    end

  end

end
