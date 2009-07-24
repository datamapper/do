
module DataObjects

  module Postgres

    class Transaction < DataObjects::Transaction

      def begin
        cmd = "BEGIN"
        connection.create_command(cmd).execute_non_query
      end

      def begin_prepared
        cmd = "BEGIN"
        connection.create_command(cmd).execute_non_query
      end

      def commit
        cmd = "COMMIT"
        connection.create_command(cmd).execute_non_query
      end

      def commit_prepared
        cmd = "COMMIT PREPARED '#{id}'"
        connection.create_command(cmd).execute_non_query
      end

      def rollback
        cmd = "ROLLBACK"
        connection.create_command(cmd).execute_non_query
      end

      def rollback_prepared
        cmd = "ROLLBACK PREPARED '#{id}'"
        connection.create_command(cmd).execute_non_query
      end

      def prepare
        cmd = "PREPARE TRANSACTION '#{id}'"
        connection.create_command(cmd).execute_non_query
      end

    end

  end

end
