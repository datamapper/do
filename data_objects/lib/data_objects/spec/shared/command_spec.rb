WINDOWS = Gem.win_platform? || (JRUBY && ENV_JAVA['os.name'] =~ /windows/i)

shared_examples_for 'a Command' do

  before :all do
    setup_test_environment
  end

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
    @command    = @connection.create_command("INSERT INTO users (name) VALUES (?)")
    @reader     = @connection.create_command("SELECT code, name FROM widgets WHERE ad_description = ?")
  end

  after do
    @connection.close
  end

  it { @command.should be_kind_of(DataObjects::Command) }

  it { @command.should respond_to(:execute_non_query) }

  describe 'execute_non_query' do

    describe 'with an invalid statement' do

      before do
        @invalid_command = @connection.create_command("INSERT INTO non_existent_table (tester) VALUES (1)")
      end

      it 'should raise an error on an invalid query' do
        expect { @invalid_command.execute_non_query }.to raise_error(DataObjects::SQLError)
      end

      it 'should raise an error with too few binding parameters' do
        expect { @command.execute_non_query("Too", "Many") }.to raise_error(ArgumentError,
          /Binding mismatch: 2 for 1/)
      end

      it 'should raise an error with too many binding parameters' do
        expect { @command.execute_non_query }.to raise_error(ArgumentError,
          /Binding mismatch: 0 for 1/)
      end

    end

    describe 'with a valid statement' do

      it 'should not raise an error with an explicit nil as parameter' do
        expect { @command.execute_non_query(nil) }.not_to raise_error(ArgumentError)
      end

    end

    describe 'with a valid statement and ? inside quotes' do

      before do
        @command_with_quotes = @connection.create_command("INSERT INTO users (name) VALUES ('will it work? ')")
      end

      it 'should not raise an error' do
        expect { @command_with_quotes.execute_non_query }.not_to raise_error(ArgumentError)
      end

    end

  end

  it { @command.should respond_to(:execute_reader) }

  describe 'execute_reader' do

    describe 'with an invalid reader' do

      before do
        @invalid_reader = @connection.create_command("SELECT * FROM non_existent_widgets WHERE ad_description = ?")
      end

      it 'should raise an error on an invalid query' do
        # FIXME JRuby (and MRI): Should this be an ArgumentError or DataObjects::SQLError?
        expect { @invalid_reader.execute_reader }.to raise_error # (ArgumentError, DataObjects::SQLError)
      end

      it 'should raise an error with too few binding parameters' do
        expect { @reader.execute_reader("Too", "Many") }.to raise_error(ArgumentError,
          /Binding mismatch: 2 for 1/)
      end

      it 'should raise an error with too many binding parameters' do
        expect { @reader.execute_reader }.to raise_error(ArgumentError,
          /Binding mismatch: 0 for 1/)
      end

    end

    describe 'with a valid reader' do

      it 'should not raise an error with an explicit nil as parameter' do
        expect { @reader.execute_reader(nil) }.not_to raise_error(ArgumentError)
      end

    end

    describe 'with a valid reader and ? inside column alias' do

      before do
        @reader_with_quotes = @connection.create_command("SELECT code AS \"code?\", name FROM widgets WHERE ad_description = ?")
      end

      it 'should not raise an error' do
        expect { @reader_with_quotes.execute_reader(nil) }.not_to raise_error(ArgumentError)
      end

    end


  end

  it { @command.should respond_to(:set_types) }

  describe 'set_types' do

    describe 'is invalid when used with a statement' do

      before do
        @command.set_types(String)
      end

      it 'should raise an error when types are set' do
        expect { @command.execute_non_query }.to raise_error(ArgumentError)
      end

    end

    describe 'with an invalid reader' do

      it 'should raise an error with too few types' do
        @reader.set_types(String)
        expect { @reader.execute_reader("One parameter") }.to raise_error(ArgumentError,
          /Field-count mismatch. Expected 1 fields, but the query yielded 2/)
      end

      it 'should raise an error with too many types' do
        @reader.set_types(String, String, BigDecimal)
        expect { @reader.execute_reader("One parameter") }.to raise_error(ArgumentError,
          /Field-count mismatch. Expected 3 fields, but the query yielded 2/)
      end

    end

    describe 'with a valid reader' do

      it 'should not raise an error with correct number of types' do
        @reader.set_types(String, String)
        expect { @result = @reader.execute_reader('Buy this product now!') }.not_to raise_error(ArgumentError)
        expect { @result.next!  }.not_to raise_error(DataObjects::DataError)
        expect { @result.values }.not_to raise_error(DataObjects::DataError)
        @result.close
      end

      it 'should also support old style array argument types' do
        @reader.set_types([String, String])
        expect { @result = @reader.execute_reader('Buy this product now!') }.not_to raise_error(ArgumentError)
        expect { @result.next!  }.not_to raise_error(DataObjects::DataError)
        expect { @result.values }.not_to raise_error(DataObjects::DataError)
        @result.close
      end

      it 'should allow subtype types' do
        class MyString < String; end
        @reader.set_types(MyString, String)
        expect { @result = @reader.execute_reader('Buy this product now!') }.not_to raise_error(ArgumentError)
        expect { @result.next!  }.not_to raise_error(DataObjects::DataError)
        expect { @result.values }.not_to raise_error(DataObjects::DataError)
        @result.close
      end
    end

  end

  it { @command.should respond_to(:to_s) }

  describe 'to_s' do

  end


end

shared_examples_for 'a Command with async' do

  before :all do
    setup_test_environment
  end

  describe 'running queries in parallel' do

    before do

      threads = []

      @start = Time.now
      4.times do |i|
        threads << Thread.new do
          begin
            connection = DataObjects::Connection.new(CONFIG.uri)
            command = connection.create_command(CONFIG.sleep)
            if CONFIG.sleep =~ /^SELECT/i
              reader = command.execute_reader
              reader.next!
              reader.close
            else
              result = command.execute_non_query
            end
          ensure
            # Always make sure the connection gets released back into the pool.
            connection.close
          end
        end
      end

      threads.each{|t| t.join }
      @finish = Time.now
    end

    it "should finish within 2 seconds" do
      pending_if("Ruby on Windows doesn't support asynchronous operations", WINDOWS) do
        (@finish - @start).should < 2
      end
    end

  end
end
