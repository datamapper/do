shared_examples_for 'raising a SQLError' do

  before :all do
    setup_test_environment
  end

  describe "an invalid query" do

    it 'should raise an error' do
      @connection = DataObjects::Connection.new(CONFIG.uri)
      invalid_query = @connection.create_command("SLCT * FROM widgets WHERE ad_description = ? order by id")
      expect { invalid_query.execute_reader('Buy this product now!') }.to raise_error(DataObjects::SQLError)
      @connection.close
    end

  end


  describe "an invalid result set" do

    it 'should raise an error' do
      @connection = DataObjects::Connection.new(CONFIG.uri)
      invalid_result = @connection.create_command("SELECT MAX((SELECT 1 UNION SELECT 2))")
      expect { invalid_result.execute_reader }.to raise_error(DataObjects::SQLError)
      @connection.close
    end

  end

end
