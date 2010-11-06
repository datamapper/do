module DataObjects

  module Mock
    class Connection < DataObjects::Connection
      def initialize(uri)
        @uri = uri
      end

      def query(*args)
        Reader.new
      end

      def execute(*args)
        Result.new(0, nil)
      end

      def dispose
        nil
      end
    end

    class Result < DataObjects::Result
    end

    class Reader < DataObjects::Reader
    end
  end

end
