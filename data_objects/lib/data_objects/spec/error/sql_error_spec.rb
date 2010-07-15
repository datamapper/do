shared 'raising a SQLError' do

  setup_test_environment

  before do
    @connection     = DataObjects::Connection.new(CONFIG.uri)
    @invalid_query  = @connection.create_command("SLCT * FROM widgets WHERE ad_description = ? order by id")
    @invalid_result = @connection.create_command("SELECT MAX((SELECT 1 UNION SELECT 2))")
  end

  it 'should raise an error on an invalid query' do
    should.raise(DataObjects::SQLError) { @invalid_query.execute_reader('Buy this product now!') }
  end

  it 'should raise on an invalid result set' do
    should.raise(DataObjects::SQLError) { @invalid_result.execute_reader }
  end

end
