require 'digest'
require 'digest/sha2'

module DataObjects

  class Transaction

    # The host name. Note, this relies on the host name being configured and resolvable using DNS
    HOST = "#{Socket::gethostbyname(Socket::gethostname)[0]}" rescue "localhost"
    @@counter = 0

    # The connection object allocated for this transaction
    attr_reader :connection
    # A unique ID for this transaction
    attr_reader :id

    # Instantiate the Transaction subclass that's appropriate for this uri scheme
    def self.create_for_uri(uri)
      uri = uri.is_a?(String) ? URI::parse(uri) : uri
      DataObjects.const_get(uri.scheme.capitalize)::Transaction.new(uri)
    end

    #
    # Creates a Transaction bound to a connection for the given DataObjects::URI
    #
    def initialize(uri)
      @connection = DataObjects::Connection.new(uri)
      @id = Digest::SHA256.hexdigest("#{HOST}:#{$$}:#{Time.now.to_f}:#{@@counter += 1}")
    end

    # Close the connection for this Transaction
    def close
      @connection.close
    end

    def begin
      cmd = "BEGIN"
      connection.create_command(cmd).execute_non_query
    end

    def commit
      cmd = "COMMIT"
      connection.create_command(cmd).execute_non_query
    end

    def rollback
      cmd = "ROLLBACK"
      connection.create_command(cmd).execute_non_query
    end

    def prepare; not_implemented; end;
    def begin_prepared; not_implemented; end;
    def commit_prepared; not_implemented; end;
    def rollback_prepared; not_implemented; end;
    def prepare; not_implemented; end;

  private
    def not_implemented
      raise NotImplementedError
    end
  end
end
