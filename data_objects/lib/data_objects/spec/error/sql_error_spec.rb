shared 'raising a SQLError' do

  setup_test_environment

  before do
    @connection     = DataObjects::Connection.new(CONFIG.uri)
    @invalid_query  = @connection.query("SLCT * FROM widgets WHERE ad_description = ? order by id", 'Buy this product now!')
  end

  it 'should raise an error on an invalid query' do
    should.raise(DataObjects::SQLError) { @invalid_query.first }
  end

  it 'should raise on an invalid result set' do
    should.raise(DataObjects::SQLError) { @connection.execute("SELECT MAX((SELECT 1 UNION SELECT 2))") }
  end

end
