shared 'raising a SQLError' do

  setup_test_environment

  describe "an invalid query" do

    it 'should raise an error' do
      @connection = DataObjects::Connection.new(CONFIG.uri)
      invalid_query = @connection.create_command("SLCT * FROM widgets WHERE ad_description = ? order by id")
      should.raise(DataObjects::SQLError) { invalid_query.execute_reader('Buy this product now!') }
      @connection.close
    end

  end


  describe "an invalid result set" do

    it 'should raise an error' do
      @connection = DataObjects::Connection.new(CONFIG.uri)
      invalid_result = @connection.create_command("SELECT MAX((SELECT 1 UNION SELECT 2))")
      should.raise(DataObjects::SQLError) { invalid_result.execute_reader }
      @connection.close
    end

  end

end
