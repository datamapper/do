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
  end
  
end