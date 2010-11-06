shared 'supporting Integer' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading an Integer' do

    describe 'with automatic typecasting' do

      before do
        @reader = @connection.query("SELECT id FROM widgets WHERE ad_description = ?", 'Buy this product now!')
        @values = @reader.first
      end

      it 'should return the correctly typed result' do
        @values.first.should.be.kind_of(Integer)
      end

      it 'should return the correct result' do
        #Some of the drivers starts autoincrementation from 0 not 1
        @values.first.should.satisfy { |val| val == 1 or val == 0 }
      end

    end

    describe 'with manual typecasting' do

      before do
        @reader = @connection.query("SELECT weight FROM widgets WHERE ad_description = ?", 'Buy this product now!')
        @reader.set_types(Integer)
        @values = @reader.first
      end

      it 'should return the correctly typed result' do
        @values.first.should.be.kind_of(Integer)
      end

      it 'should return the correct result' do
        @values.first.should == 13
      end

    end

  end

  describe 'writing an Integer' do

    before do
      @reader = @connection.query("SELECT id FROM widgets WHERE id = ?", 2)
      @values = @reader.first
    end

    it 'should return the correct entry' do
      @values.first.should == 2
    end

  end

  describe 'writing a big Integer' do

    before do
      @connection.execute("UPDATE widgets SET super_number = ? WHERE id = 10", 2147483648) # bigger than Integer.MAX in java !!
      @reader = @connection.query("SELECT super_number FROM widgets WHERE id = ?", 10)
      @values = @reader.first
    end

    it 'should return the correct entry' do
      @values.first.should == 2147483648
    end

  end

end
