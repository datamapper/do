require 'socket'
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
    def initialize(uri, connection = nil)
      @connection = connection || DataObjects::Connection.new(uri)
      # PostgreSQL can't handle the full 64 bytes.  This should be enough for everyone.
      @id = Digest::SHA256.hexdigest("#{HOST}:#{$$}:#{Time.now.to_f}:#{@@counter += 1}")[0..-2]
    end

    # Close the connection for this Transaction
    def close
      @connection.close
    end

    def begin
      run "BEGIN"
    end

    def commit
      run "COMMIT"
    end

    def rollback
      run "ROLLBACK"
    end

    def prepare; not_implemented; end;
    def begin_prepared; not_implemented; end;
    def commit_prepared; not_implemented; end;
    def rollback_prepared; not_implemented; end;
    def prepare; not_implemented; end;

  protected
    def run(cmd)
      connection.create_command(cmd).execute_non_query
    end

  private
    def not_implemented
      raise NotImplementedError
    end
  end # class Transaction

  class SavePoint < Transaction
    # We don't bounce through DO::<Adapter/scheme>::SavePoint because there
    # doesn't appear to be any custom SQL to support this.
    def self.create_for_uri(uri, connection)
      uri = uri.is_a?(String) ? URI::parse(uri) : uri
      DataObjects::SavePoint.new(uri, connection)
    end

    # SavePoints can only occur in the context of a Transaction, thus they
    # re-use TXN's connection (which was acquired from the connection pool
    # legitimately via DO::Connection.new).  We no-op #close in SP because
    # calling DO::Connection#close will release the connection back into the
    # pool (before the top-level Transaction might be done with it).
    def close
        # no-op
    end

    def begin
      run %{SAVEPOINT "#{@id}"}
    end

    def commit
      run %{RELEASE SAVEPOINT "#{@id}"}
    end

    def rollback
      run %{ROLLBACK TO SAVEPOINT "#{@id}"}
    end
  end # class SavePoint

end
