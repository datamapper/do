module DataObjects

  module SqlServer

    class Transaction < DataObjects::Transaction

      def begin
        connection.instance_variable_get("@connection").autocommit = false
      end

      def commit
        connection.instance_variable_get("@connection").commit
      ensure
        connection.instance_variable_get("@connection").autocommit = true
      end

      def rollback
        connection.instance_variable_get("@connection").rollback
      ensure
        connection.instance_variable_get("@connection").autocommit = true
      end

      def rollback_prepared
        # TODO: what should be done differently?
        rollback
      end

      def prepare
        # TODO: what should be done here?
      end

    end

  end

end
