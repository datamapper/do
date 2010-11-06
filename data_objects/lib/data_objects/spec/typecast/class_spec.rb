shared 'supporting Class' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a Class' do

    describe 'with manual typecasting' do

      before do
        @reader = @connection.query("SELECT whitepaper_text FROM widgets WHERE ad_description = ?", 'Buy this product now!')
        @reader.set_types(Class)
        @values = @reader.first
      end

      it 'should return the correctly typed result' do
        @values.first.should.be.kind_of(Class)
      end

      it 'should return the correct result' do
        @values.first.should == String
      end

    end

  end

  describe 'writing a Class' do

    before do
      @reader = @connection.query("SELECT whitepaper_text FROM widgets WHERE whitepaper_text = ?", String)
      @values = @reader.first
    end

    it 'should return the correct entry' do
      @values.first.should == "String"
    end

  end

end
