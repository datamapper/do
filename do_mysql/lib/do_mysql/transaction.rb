
module DataObjects

  module Mysql

    class Transaction < DataObjects::Transaction

      def begin_prepared
        cmd = "XA START '#{id}'"
        connection.create_command(cmd).execute_non_query
      end

      def commit_prepared
        cmd = "XA COMMIT '#{id}'"
        connection.create_command(cmd).execute_non_query
      end

      def rollback_prepared
        cmd = "XA ROLLBACK '#{id}'"
        connection.create_command(cmd).execute_non_query
      end

      def prepare
        finalize_transaction
        cmd = "XA PREPARE '#{id}'"
        connection.create_command(cmd).execute_non_query
      end

      private

      def finalize_transaction
        cmd = "XA END '#{id}'"
        connection.create_command(cmd).execute_non_query
      end

    end

  end

end
