share_examples_for 'a Connection' do

  include DataObjectsSpecHelpers

  before :all do
    setup_test_environment
  end

  before :each do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after :each do
    @connection.close
  end

  it { @connection.should be_kind_of(DataObjects::Connection) }
  it { @connection.should be_kind_of(DataObjects::Pooling) }

  it { @connection.should respond_to(:dispose) }

  describe 'dispose' do

    describe 'on open connection' do
      before do
        @open_connection = DataObjects::Connection.new("#{@driver}://#{@user}:#{@password}@#{@host}:#{@port}#{@database}")
        @open_connection.detach
      end

      after do
        @open_connection.close
      end

      it { @open_connection.dispose.should be_true }
    end

    describe 'on closed connection' do
      before do
        @closed_connection = DataObjects::Connection.new("#{@driver}://#{@user}:#{@password}@#{@host}:#{@port}#{@database}")
        @closed_connection.detach
        @closed_connection.dispose
      end

      after do
        @closed_connection.close
      end

      it { @closed_connection.dispose.should be_false }

      it 'should raise an error on creating a command' do
        lambda { @closed_connection.create_command("INSERT INTO non_existent_table (tester) VALUES (1)").execute_non_query }.should raise_error
      end
    end

  end

  it { @connection.should respond_to(:create_command) }

  describe 'create_command' do
    it { @connection.create_command('This is a dummy command').should be_kind_of(DataObjects::Command) }
  end

  describe 'various connection URIs' do

    def test_connection(conn)
      reader = conn.create_command(CONFIG.testsql || "SELECT 1").execute_reader
      reader.next!
      reader.values[0]
    end

    after do
      @open_connection.close if @open_connection
    end

    it 'should open with an uri object' do
      uri = DataObjects::URI.new(
              @driver,
              @user,
              @password,
              @host,
              @port.to_i,
              @database,
              nil, nil
            )
      test_connection(DataObjects::Connection.new(uri)).should == 1
    end

    it 'should work with non jdbc URIs' do
      conn = DataObjects::Connection.new("#{CONFIG.uri.sub(/jdbc:/, '')}")
      test_connection(conn).should == 1
    end

    if JRUBY
      it 'should work with jdbc URIs' do
        conn = DataObjects::Connection.new(CONFIG.jdbc_uri || "jdbc:#{CONFIG.uri.sub(/jdbc:/, '')}")
        test_connection(conn).should == 1
      end
    end
  end
end

share_examples_for 'a Connection with authentication support' do

  before :all do
    %w[ @driver @user @password @host @port @database ].each do |ivar|
      raise "+#{ivar}+ should be defined in before block" unless instance_variable_get(ivar)
    end

  end

  describe 'with an invalid URI' do

    def connecting_with(uri)
      lambda { DataObjects::Connection.new(uri) }
    end

    it 'should raise an error if no database specified' do
      connecting_with("#{@driver}://#{@user}:#{@password}@#{@host}:#{@port}").should raise_error
    end

    it 'should raise an error if bad username is given' do
      connecting_with("#{@driver}://thisreallyshouldntexist:#{@password}@#{@host}:#{@port}#{@database}").should raise_error
    end

    it 'should raise an error if bad password is given' do
      connecting_with("#{@driver}://#{@user}:completelyincorrectpassword:#{@host}:#{@port}#{@database}").should raise_error
    end

    it 'should raise an error if an invalid port is given' do
      connecting_with("#{@driver}://#{@user}:#{@password}:#{@host}:648646543#{@database}").should raise_error
    end

    it 'should raise an error if an invalid database is given' do
      connecting_with("#{@driver}://#{@user}:#{@password}:#{@host}:#{@port}/someweirddatabase").should raise_error
    end

    it 'should raise an error with a meaningless URI' do
      connecting_with("#{@driver}://peekaboo$2!@#4543").should raise_error
    end

  end

end

share_examples_for 'a Connection with SSL support' do

  if DataObjectsSpecHelpers.test_environment_supports_ssl?
    describe 'connecting with SSL' do

      it 'should connect securely' do
        DataObjects::Connection.new("#{CONFIG.uri}?#{CONFIG.ssl}").secure?.should be_true
      end

    end
  end

  describe 'connecting without SSL' do

    it 'should not connect securely' do
      DataObjects::Connection.new(CONFIG.uri).secure?.should be_false
    end

  end

end

share_examples_for 'a Connection via JDNI' do

  if JRUBY
    describe 'connecting with JNDI' do

      before :each do
        begin
          @jndi = Java::data_objects.JNDITestSetup.new("jdbc:#{CONFIG.uri}".gsub(/:sqlite3:/, ':sqlite:'), CONFIG.jdbc_driver, 'mydb')
          @jndi.setup()
        rescue
          puts "use (after installation of maven) to test JNDI:"
          puts "mvn rails:spec -Drails.fork=false"
        end
      end

      after :each do
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
          end
        end
      end

    end
  end
end
