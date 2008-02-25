require File.dirname(__FILE__) + '/../lib/data_objects'

module DataObjects
  
  module Mock
    class Connection < DataObjects::Connection
      def initialize(uri)
        @uri = uri
      end
      
      def real_close
        nil
      end
    end
    
    class Command < DataObjects::Command
      def execute_non_query(*args)
        Result.new(self, 0, nil)
      end
    end
    
    class Result < DataObjects::Result
    end
    
    class Reader < DataObjects::Reader
    end
  end
  
end