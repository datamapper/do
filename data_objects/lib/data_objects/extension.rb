module DataObjects
  class Extension

    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

  end
end