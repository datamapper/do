shared 'a Connection' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  it 'should be a kind of Connection'    do @connection.should.be.kind_of(::DataObjects::Connection) end
  it 'should be a kind of Pooling'       do @connection.should.be.kind_of(::DataObjects::Pooling)    end
  it 'should respond to #dispose'        do @connection.should.respond_to?(:dispose)                 end
  it 'should respond to #create_command' do @connection.should.respond_to?(:create_command)          end

  describe 'create_command' do
    it 'should be a kind of Command' do
      @connection.create_command('This is a dummy command').should.be.kind_of(DataObjects::Command)
    end
  end

  describe 'various connection URIs' do
    def test_connection(conn)
      reader = conn.create_command(CONFIG.testsql || "SELECT 1").execute_reader
      reader.next!
      reader.values[0]
    end

    it 'should open with an uri object' do
      uri = DataObjects::URI.new(
              @driver,
              @user,
              @password,
              @host,
              @port && @port.to_i,
              @database,
              nil, nil
            )
      conn = DataObjects::Connection.new(uri)
      test_connection(conn).should == 1
      conn.close
    end

    it 'should work with non-JDBC URLs' do
      conn = DataObjects::Connection.new("#{CONFIG.uri.sub(/jdbc:/, '')}")
      test_connection(conn).should == 1
      conn.close
    end

  end

  describe 'dispose' do

    describe 'on open connection' do

      it 'dispose should be true' do
        conn = DataObjects::Connection.new("#{@driver}://#{@user}:#{@password}@#{@host}:#{@port}#{@database}")
        conn.detach
        conn.dispose.should.be.true
        conn.close
      end

    end

    describe 'on closed connection' do

      before do
        @closed_connection = DataObjects::Connection.new("#{@driver}://#{@user}:#{@password}@#{@host}:#{@port}#{@database}")
        @closed_connection.detach
        @closed_connection.dispose
      end

      after do
        @closed_connection.close
        @closed_connection = nil
      end

      it 'dispose should be false' do
        @closed_connection.dispose.should.be.false
      end

      it 'should raise an error on creating a command' do
        should.raise(DataObjects::ConnectionError) {
          @closed_connection.create_command("INSERT INTO non_existent_table (tester) VALUES (1)").execute_non_query
        }
      end
    end

  end

end

shared 'a Connection with authentication support' do

  %w[ @driver @user @password @host @port @database ].each do |ivar|
    raise "+#{ivar}+ should be defined in before block" unless instance_variable_get(ivar)
  end

  describe 'with an invalid URI' do

    # FIXME JRuby (and MRI): Should these be ArgumentError or DataObjects::SQLError?

    def connecting_with(uri)
      lambda { DataObjects::Connection.new(uri) }
    end

    it 'should raise an error if no database specified' do
      connecting_with("#{@driver}://#{@user}:#{@password}@#{@host}:#{@port}").should.raise(ArgumentError, DataObjects::Error)
    end

    it 'should raise an error if bad username is given' do
      connecting_with("#{@driver}://thisreallyshouldntexist:#{@password}@#{@host}:#{@port}#{@database}").should.raise(ArgumentError, DataObjects::Error)
    end

    it 'should raise an error if bad password is given' do
      connecting_with("#{@driver}://#{@user}:completelyincorrectpassword:#{@host}:#{@port}#{@database}").should.raise(ArgumentError, DataObjects::Error)
    end

    it 'should raise an error if an invalid port is given' do
      connecting_with("#{@driver}://#{@user}:#{@password}:#{@host}:648646543#{@database}").should.raise(ArgumentError, DataObjects::Error)
    end

    it 'should raise an error if an invalid database is given' do
      connecting_with("#{@driver}://#{@user}:#{@password}:#{@host}:#{@port}/someweirddatabase").should.raise(ArgumentError, DataObjects::Error)
    end

    it 'should raise an error with a meaningless URI' do
      connecting_with("#{@driver}://peekaboo$2!@#4543").should.raise(Addressable::URI::InvalidURIError)
    end

  end

end

shared 'a Connection with JDBC URL support' do

  def test_connection(conn)
    reader = conn.create_command(CONFIG.testsql || "SELECT 1").execute_reader
    reader.next!
    result = reader.values[0]
    reader.close
    conn.close
  end

  it 'should work with JDBC URLs' do
    conn = DataObjects::Connection.new(CONFIG.jdbc_uri || "jdbc:#{CONFIG.uri.sub(/jdbc:/, '')}")
    test_connection(conn).should == 1
    conn.close
  end

end if JRUBY

shared 'a Connection with SSL support' do

  if DataObjectsSpecHelpers.test_environment_supports_ssl?
    describe 'connecting with SSL' do

      it 'should connect securely' do
        conn = DataObjects::Connection.new("#{CONFIG.uri}?#{CONFIG.ssl}")
        conn.secure?.should.be.true
        conn.close
      end

    end
  end

  describe 'connecting without SSL' do

    it 'should not connect securely' do
      conn = DataObjects::Connection.new(CONFIG.uri)
      conn.secure?.should.be.false
      conn.close
    end

  end

end

shared 'a Connection via JDNI' do

  if JRUBY
    describe 'connecting with JNDI' do

      before do
        begin
          @jndi = Java::data_objects.JNDITestSetup.new("jdbc:#{CONFIG.uri}".gsub(/:sqlite3:/, ':sqlite:'), CONFIG.jdbc_driver, 'mydb')
          @jndi.setup()
        rescue
          puts "use (after installation of maven) to test JNDI:"
          puts "mvn rails:spec -Drails.fork=false"
        end
      end

      after do
        @jndi.teardown() unless @jndi.nil?
      end

      unless @jndi.nil?
        it 'should connect' do
          begin
            c = DataObjects::Connection.new("java:comp/env/jdbc/mydb?scheme=#{CONFIG.scheme}")
            c.should_not be_nil
          rescue => e
            if e.message =~ /java.naming.factory.initial/
              puts "use (after installation of maven) to test JNDI:"
              puts "mvn rails:spec -Drails.fork=false"
            end
          else
            c.close
          end
        end
      end

    end
  end
end
