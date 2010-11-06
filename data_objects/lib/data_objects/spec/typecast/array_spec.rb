shared 'supporting Array' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'passing an Array as a parameter in execute_reader' do

    before do
      @reader = @connection.query("SELECT * FROM widgets WHERE id in ?", [2,3,4,5])
    end

    it 'should return correct number of rows' do
      counter  = 0
      @reader.each do |row|
        counter += 1
      end
      counter.should == 4
    end

  end
end
