shared 'a Result' do

  setup_test_environment

  describe 'affected_rows' do

    before do
      @connection = DataObjects::Connection.new(CONFIG.uri)
      @result    = @connection.create_command("INSERT INTO users (name) VALUES (?)").execute_non_query("monkey")
    end

    after do
      @connection.close
    end

    it 'should respond to #affected_rows' do @result.should.respond_to(:affected_rows) end

    it 'should return the number of affected rows' do
      @result.affected_rows.should == 1
    end

  end

end

shared 'a Result which returns inserted key with sequences' do

  describe 'insert_id' do

    before do
      setup_test_environment
      @connection = DataObjects::Connection.new(CONFIG.uri)
      command = @connection.create_command("INSERT INTO users (name) VALUES (?)")
      # execute the command twice and expose the second result
      command.execute_non_query("monkey")
      @result = command.execute_non_query("monkey")
    end

    after do
      @connection.close
    end

    it 'should respond to #affected_rows' do @result.should.respond_to(:affected_rows) end

    it 'should return the insert_id' do
      # This is actually the 2nd record inserted
      @result.insert_id.should == 2
    end

  end

end

shared 'a Result which returns nil without sequences' do

  describe 'insert_id' do

    before do
      setup_test_environment
      @connection = DataObjects::Connection.new(CONFIG.uri)
      command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES (?)")
      # execute the command twice and expose the second result
      @result = command.execute_non_query("monkey")
    end

    after do
      @connection.close
    end

    it 'should respond to #affected_rows' do @result.should.respond_to(:affected_rows) end

    it 'should return the insert_id' do
      # This is actually the 2nd record inserted
      @result.insert_id.should.be.nil
    end

  end

end
