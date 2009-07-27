share_examples_for 'a driver supporting encodings' do

  before :each do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after :each do
    @connection.close
  end


  it { @connection.should respond_to(:character_set) }

  describe 'character_set' do

    it 'uses utf8 by default' do
      @connection.character_set.should == 'UTF-8'
    end

    describe 'sets the character set through the URI' do
      before do
        # @latin1_connection = DataObjects::Connection.new("#{CONFIG.uri}?encoding=latin1")
        @latin1_connection = DataObjects::Connection.new("#{CONFIG.scheme}://#{CONFIG.user}:#{CONFIG.pass}@#{CONFIG.host}:#{CONFIG.port}#{CONFIG.database}?encoding=ISO-8859-1")
      end

      after { @latin1_connection.close }

      it { @latin1_connection.character_set.should == 'ISO-8859-1' }
    end

    describe 'uses UTF-8 when an invalid encoding is given' do
      before do
        @latin1_connection = DataObjects::Connection.new("#{CONFIG.scheme}://#{CONFIG.user}:#{CONFIG.pass}@#{CONFIG.host}:#{CONFIG.port}#{CONFIG.database}?encoding=ISO-INVALID")
      end

      after { @latin1_connection.close }

      it { @latin1_connection.character_set.should == 'UTF-8' }
    end


  end
end
