
module DataObjects

  module Sqlite3

    class Transaction < DataObjects::Transaction

      def begin_prepared
        raise NotImplementedError
      end

      def commit_prepared
        raise NotImplementedError
      end

      def rollback_prepared
        raise NotImplementedError
      end

      def prepare
        raise NotImplementedError
      end

    end

  end

end
