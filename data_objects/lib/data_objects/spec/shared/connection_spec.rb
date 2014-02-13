def test_connection(conn)
  reader = conn.create_command(CONFIG.testsql || "SELECT 1").execute_reader
  reader.next!
  result = reader.values[0]
  result
ensure
  reader.close
  conn.close
end

shared_examples_for 'a Connection' do

  before :all do
    setup_test_environment
  end

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  it { @connection.should be_kind_of(DataObjects::Connection) }
  it { @connection.should be_kind_of(DataObjects::Pooling) }

  it { @connection.should respond_to(:dispose) }
  it 'should respond to #create_command' do @connection.should respond_to(:create_command)          end

  describe 'create_command' do
    it 'should be a kind of Command' do
      @connection.create_command('This is a dummy command').should be_kind_of(DataObjects::Command)
    end
  end

  describe 'various connection URIs' do

    it 'should open with an uri object' do
      uri = DataObjects::URI.new(
              :scheme   => @driver,
              :user     => @user,
              :password => @password,
              :host     => @host,
              :port     => @port && @port.to_i,
              :path     => @database
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
        conn = DataObjects::Connection.new(CONFIG.uri)
        conn.detach
        conn.dispose.should be_true
        conn.close
      end

    end

    describe 'on closed connection' do

      before do
        @closed_connection = DataObjects::Connection.new(CONFIG.uri)
        @closed_connection.detach
        @closed_connection.dispose
      end

      after do
        @closed_connection.close
        @closed_connection = nil
      end

      it { @closed_connection.dispose.should be_false }

      it 'should raise an error on creating a command' do
        expect {
          @closed_connection.create_command("INSERT INTO non_existent_table (tester) VALUES (1)").execute_non_query
        }.to raise_error(DataObjects::ConnectionError)
      end
    end

  end

end

shared_examples_for 'a Connection with authentication support' do

  before :all do
    %w[ @driver @user @password @host @port @database ].each do |ivar|
      raise "+#{ivar}+ should be defined in before block" unless instance_variable_get(ivar)
    end
  end

  describe 'with an invalid URI' do

    # FIXME JRuby (and MRI): Should these be ArgumentError or DataObjects::SQLError?

    def connecting_with(uri)
      lambda { DataObjects::Connection.new(uri) }
    end

    it 'should raise an error if bad username is given' do
      connecting_with("#{@driver}://thisreallyshouldntexist:#{@password}@#{@host}:#{@port}#{@database}").should raise_error #(ArgumentError, DataObjects::Error)
    end

    it 'should raise an error if bad password is given' do
      connecting_with("#{@driver}://#{@user}:completelyincorrectpassword:#{@host}:#{@port}#{@database}").should raise_error #(ArgumentError, DataObjects::Error)
    end

    it 'should raise an error if an invalid port is given' do
      connecting_with("#{@driver}://#{@user}:#{@password}:#{@host}:648646543#{@database}").should raise_error #(ArgumentError, DataObjects::Error)
    end

    it 'should raise an error if an invalid database is given' do
      connecting_with("#{@driver}://#{@user}:#{@password}:#{@host}:#{@port}/someweirddatabase").should raise_error #(ArgumentError, DataObjects::Error)
    end

  end

end

shared_examples_for 'a Connection allowing default database' do
  describe 'with a URI without a database' do
    it 'should connect properly' do
      conn = DataObjects::Connection.new("#{@driver}://#{@user}:#{@password}@#{@host}:#{@port}")
      test_connection(conn).should == 1
    end
  end
end

shared_examples_for 'a Connection with JDBC URL support' do

  it 'should work with JDBC URLs' do
    conn = DataObjects::Connection.new(CONFIG.jdbc_uri || "jdbc:#{CONFIG.uri.sub(/jdbc:/, '')}")
    test_connection(conn).should == 1
  end

end if defined? JRUBY_VERSION

shared_examples_for 'a Connection with SSL support' do

  if DataObjectsSpecHelpers.test_environment_supports_ssl?
    describe 'connecting with SSL' do

      it 'should connect securely' do
        conn = DataObjects::Connection.new("#{CONFIG.uri}?#{CONFIG.ssl}")
        conn.secure?.should be_true
        conn.close
      end

    end
  end

  describe 'connecting without SSL' do

    it 'should not connect securely' do
      conn = DataObjects::Connection.new(CONFIG.uri)
      conn.secure?.should be_false
      conn.close
    end

  end

end

shared_examples_for 'a Connection via JDNI' do

  if defined? JRUBY_VERSION
    require 'java'
    begin
      require 'do_jdbc/spec/lib/tyrex-1.0.3.jar'
      require 'do_jdbc/spec/lib/javaee-api-6.0.jar'
      require 'do_jdbc/spec/lib/commons-dbcp-1.2.2.jar'
      require 'do_jdbc/spec/lib/commons-pool-1.3.jar'
    rescue LoadError
      pending 'JNDI specs currently require manual download of Tyrex and Apache Commons JARs'
      break
    end

    describe 'connecting with JNDI' do

      before(:all) do
        java_import java.lang.System
        java_import javax.naming.Context
        java_import javax.naming.NamingException
        java_import javax.naming.Reference
        java_import javax.naming.StringRefAddr
        java_import 'tyrex.naming.MemoryContext'
        java_import 'tyrex.tm.RuntimeContext'

        System.set_property(Context.INITIAL_CONTEXT_FACTORY, 'tyrex.naming.MemoryContextFactory')
        ref  = Reference.new('javax.sql.DataSource',
                             'org.apache.commons.dbcp.BasicDataSourceFactory', nil)
        ref.add(StringRefAddr.new('driverClassName',  CONFIG.jdbc_driver))
        ref.add(StringRefAddr.new('url',              (CONFIG.jdbc_uri || CONFIG.uri)))
        ref.add(StringRefAddr.new('username',         CONFIG.user))
        ref.add(StringRefAddr.new('password',         CONFIG.pass))

        @root = MemoryContext.new(nil)
        ctx   = @root.createSubcontext('comp')
        ctx   = ctx.createSubcontext('env')
        ctx   = ctx.createSubcontext('jdbc')
        ctx.bind('mydb', ref)
      end

      before do
        runCtx = RuntimeContext.newRuntimeContext(@root, nil)
        RuntimeContext.setRuntimeContext(runCtx)
      end

      after do
        RuntimeContext.unsetRuntimeContext()
      end

      it 'should connect' do
        begin
          c = DataObjects::Connection.new("java:comp/env/jdbc/mydb?driver=#{CONFIG.driver}")
          c.should_not be_nil
          test_connection(c).should == 1
        ensure
          c.close if c
        end
      end
    end
  end
end
