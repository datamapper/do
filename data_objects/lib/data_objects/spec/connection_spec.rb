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
  it { @connection.should be_kind_of(Extlib::Pooling) }

  it { @connection.should respond_to(:dispose) }

  describe 'dispose' do

    describe 'on open connection' do
      before do
        @open_connection = DataObjects::Connection.new("#{@driver}://#{@user}:#{@password}@#{@host}:#{@port}/#{@database}")
        @open_connection.detach
      end

      after do
        @open_connection.close
      end

      it { @open_connection.dispose.should be_true }
    end

    describe 'on closed connection' do
      before do
        @closed_connection = DataObjects::Connection.new("#{@driver}://#{@user}:#{@password}@#{@host}:#{@port}/#{@database}")
        @closed_connection.detach
        @closed_connection.dispose
      end

      after do
        @closed_connection.close
      end

      it { @closed_connection.dispose.should be_false }

      it 'should raise an error on creating a command' do
        lambda { @closed_connection.create_command("INSERT INTO non_existant_table (tester) VALUES (1)").execute_non_query }.should raise_error
      end
    end

  end

  it { @connection.should respond_to(:create_command) }

  describe 'create_command' do
    it { @connection.create_command('This is a dummy command').should be_kind_of(DataObjects::Command) }
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
      connecting_with("#{@driver}://#{@user}:#{@password}@#{@host}:#{@port}/").should raise_error
    end

    it 'should raise an error if bad username is given' do
      connecting_with("#{@driver}://thisreallyshouldntexist:#{@password}@#{@host}:#{@port}/#{@database}").should raise_error
    end

    it 'should raise an error if bad password is given' do
      connecting_with("#{@driver}://#{@user}:completelyincorrectpassword:#{@host}:#{@port}/#{@database}").should raise_error
    end

    it 'should raise an error if an invalid port is given' do
      connecting_with("#{@driver}://#{@user}:#{@password}:#{@host}:648646543/#{@database}").should raise_error
    end

    it 'should raise an error if an invalid database is given' do
      connecting_with("#{@driver}://#{@user}:#{@password}:#{@host}:#{@port}/someweirddatabase").should raise_error
    end

    it 'should raise an error with a meaningless URI' do
      connecting_with("#{@driver}://peekaboo$2!@#4543").should raise_error
    end
    it 'should raise an error with a meaningless URI' do
      connecting_with("#{@driver}://peekaboo$2!@#4543").should raise_error
    end
    it 'should raise an error with a meaningless URI' do
      connecting_with("#{@driver}://peekaboo$2!@#4543").should raise_error
    end
    it 'should raise an error with a meaningless URI' do
      connecting_with("#{@driver}://peekaboo$2!@#4543").should raise_error
    end
    it 'should raise an error with a meaningless URI' do
      connecting_with("#{@driver}://peekaboo$2!@#4543").should raise_error
    end
    it 'should raise an error with a meaningless URI' do
      connecting_with("#{@driver}://peekaboo$2!@#4543").should raise_error
    end
    it 'should raise an error with a meaningless URI' do
      connecting_with("#{@driver}://peekaboo$2!@#4543").should raise_error
    end
    it 'should raise an error with a meaningless URI' do
      connecting_with("#{@driver}://peekaboo$2!@#4543").should raise_error
    end

  end

end

share_examples_for 'a Connection with SSL support' do
  include SSLHelpers

  before :all do
    @supports_ssl, @message = test_environment_supports_ssl?(ssl_config)
  end

  def ssl_uri(query = '')
    result = "#{CONFIG.uri}?ssl=true"
    result << '&' << @ssl_query unless @ssl_query.blank?
    result << '&' << query unless query.blank?
    result
  end

  describe 'connecting with SSL' do

    it 'should connect with an SSL cipher' do
      pending_if(@message, !@supports_ssl) do
        DataObjects::Connection.new(ssl_uri).ssl_cipher.should_not be_blank
      end
    end

    it 'should connect with a specified SSL cipher' do
      pending_if(@message, !@supports_ssl) do
        DataObjects::Connection.new(ssl_uri("ssl_cipher=#{ssl_config[:cipher]}")).
          ssl_cipher.should == ssl_config[:cipher]
      end
    end

    it 'should raise an error with an invalid SSL cipher' do
      pending_if(@message, !@supports_ssl) do
        lambda { DataObjects::Connection.new(ssl_uri('ssl_cipher=someinvalidcipher')) }.
          should raise_error
      end
    end

  end

  describe 'connecting without SSL' do

    it 'should not connect with an SSL cipher' do
      DataObjects::Connection.new(CONFIG.uri).ssl_cipher.should be_nil
    end

  end

end
