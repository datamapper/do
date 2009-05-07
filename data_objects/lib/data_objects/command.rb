module DataObjects
  # Abstract base class for adapter-specific Command subclasses
  class Command

    # The Connection on which the command will be run
    attr_reader :connection

    # Create a new Command object on the specified connection
    def initialize(connection, text)
      raise ArgumentError.new("+connection+ must be a DataObjects::Connection") unless DataObjects::Connection === connection
      @connection, @text = connection, text
    end

    # Execute this command and return no dataset
    def execute_non_query(*args)
      raise NotImplementedError.new
    end

    # Execute this command and return a DataObjects::Reader for a dataset
    def execute_reader(*args)
      raise NotImplementedError.new
    end

    # Assign an array of types for the columns to be returned by this command
    def set_types(column_types)
      raise NotImplementedError.new
    end

    # Display the command text
    def to_s
      @text
    end

  end

end
