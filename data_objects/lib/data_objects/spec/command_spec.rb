WINDOWS = Gem.win_platform? || (JRUBY && ENV_JAVA['os.name'] =~ /windows/i)

shared 'a Command' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
    @command    = @connection.create_command("INSERT INTO users (name) VALUES (?)")
    @reader     = @connection.create_command("SELECT code, name FROM widgets WHERE ad_description = ?")
  end

  after do
    @connection.close
  end

  it 'should be a kind of Command' do @command.should.be.kind_of(DataObjects::Command) end

  it 'should respond to #execute_non_query' do @command.should.respond_to(:execute_non_query) end

  describe 'execute_non_query' do

    describe 'with an invalid statement' do

      before do
        @invalid_command = @connection.create_command("INSERT INTO non_existent_table (tester) VALUES (1)")
      end

      it 'should raise an error on an invalid query' do
        should.raise(DataObjects::SQLError) { @invalid_command.execute_non_query }
      end

      it 'should raise an error with too few binding parameters' do
        lambda { @command.execute_non_query("Too", "Many") }.should.raise(ArgumentError).
          message.should.match(/Binding mismatch: 2 for 1/)
      end

      it 'should raise an error with too many binding parameters' do
        lambda { @command.execute_non_query }.should.raise(ArgumentError).
          message.should.match(/Binding mismatch: 0 for 1/)
      end

    end

    describe 'with a valid statement' do

      it 'should not raise an error with an explicit nil as parameter' do
        should.not.raise(ArgumentError) { @command.execute_non_query(nil) }
      end

    end

    describe 'with a valid statement and ? inside quotes' do

      before do
        @command_with_quotes = @connection.create_command("INSERT INTO users (name) VALUES ('will it work? ')")
      end

      it 'should not raise an error' do
        should.not.raise(ArgumentError) { @command_with_quotes.execute_non_query }
      end

    end

  end

  it 'should respond to #execute_reader' do @command.should.respond_to(:execute_reader) end

  describe 'execute_reader' do

    describe 'with an invalid reader' do

      before do
        @invalid_reader = @connection.create_command("SELECT * FROM non_existent_widgets WHERE ad_description = ?")
      end

      it 'should raise an error on an invalid query' do
        # FIXME JRuby (and MRI): Should this be an ArgumentError or DataObjects::SQLError?
        should.raise(ArgumentError, DataObjects::SQLError) { @invalid_reader.execute_reader }
      end

      it 'should raise an error with too few binding parameters' do
        lambda { @reader.execute_reader("Too", "Many") }.should.raise(ArgumentError).
          message.should.match(/Binding mismatch: 2 for 1/)
      end

      it 'should raise an error with too many binding parameters' do
        lambda { @reader.execute_reader }.should.raise(ArgumentError).
          message.should.match(/Binding mismatch: 0 for 1/)
      end

    end

    describe 'with a valid reader' do

      it 'should not raise an error with an explicit nil as parameter' do
        should.not.raise(ArgumentError) { @reader.execute_reader(nil) }
      end

    end

    describe 'with a valid reader and ? inside column alias' do

      before do
        @reader_with_quotes = @connection.create_command("SELECT code AS \"code?\", name FROM widgets WHERE ad_description = ?")
      end

      it 'should not raise an error' do
        should.not.raise(ArgumentError) { @reader_with_quotes.execute_reader(nil) }
      end

    end


  end

  it 'should respond to #set_types' do @command.should.respond_to(:set_types) end

  describe 'set_types' do

    describe 'is invalid when used with a statement' do

      before do
        @command.set_types(String)
      end

      it 'should raise an error when types are set' do
        should.raise(ArgumentError) { @command.execute_non_query }
      end

    end

    describe 'with an invalid reader' do

      it 'should raise an error with too few types' do
        @reader.set_types(String)
        lambda { @reader.execute_reader("One parameter") }.should.raise(ArgumentError).
          message.should.match(/Field-count mismatch. Expected 1 fields, but the query yielded 2/)
      end

      it 'should raise an error with too many types' do
        @reader.set_types(String, String, BigDecimal)
        lambda { @reader.execute_reader("One parameter") }.should.raise(ArgumentError).
          message.should.match(/Field-count mismatch. Expected 3 fields, but the query yielded 2/)
      end

    end

    describe 'with a valid reader' do

      it 'should not raise an error with correct number of types' do
        @reader.set_types(String, String)
        should.not.raise(ArgumentError) { @result = @reader.execute_reader('Buy this product now!') }
        should.not.raise(DataObjects::SQLError) { @result.next! }
        should.not.raise(DataObjects::DataError) { @result.values }
        @result.close
      end

      it 'should also support old style array argument types' do
        @reader.set_types([String, String])
        should.not.raise(ArgumentError) { @result = @reader.execute_reader('Buy this product now!') }
        should.not.raise(DataObjects::DataError) { @result.next! }
        should.not.raise(DataObjects::DataError) { @result.values }
        @result.close
      end

      it 'should allow subtype types' do
        class MyString < String; end
        @reader.set_types(MyString, String)
        should.not.raise(ArgumentError) { @result = @reader.execute_reader('Buy this product now!') }
        should.not.raise(DataObjects::DataError) { @result.next! }
        should.not.raise(DataObjects::DataError) { @result.values }
        @result.close
      end
    end

  end

  it 'should respond to #to_s' do @command.should.respond_to(:to_s) end

  describe 'to_s' do

  end


end

shared 'a Command with async' do

  setup_test_environment

  describe 'running queries in parallel' do

    before do

      threads = []

      @start = Time.now
      4.times do |i|
        threads << Thread.new do
          connection = DataObjects::Connection.new(CONFIG.uri)
          command = connection.create_command(CONFIG.sleep)
          if CONFIG.sleep =~ /^SELECT/i
            reader = command.execute_reader
            reader.next!
            reader.close
          else
            result = command.execute_non_query
          end
          connection.close
        end
      end

      threads.each{|t| t.join }
      @finish = Time.now
    end

    after do
      @connection.close
    end

    it "should finish within 2 seconds" do
      pending_if("Ruby on Windows doesn't support asynchronous operations", WINDOWS) do
        (@finish - @start).should < 2
      end
    end

  end
end
