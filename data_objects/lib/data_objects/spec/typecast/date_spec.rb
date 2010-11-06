shared 'supporting Date' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a Date' do

    describe 'with manual typecasting' do

      before do
        @reader = @connection.query("SELECT release_datetime FROM widgets WHERE ad_description = ?", 'Buy this product now!')
        @reader.set_types(Date)
        @values = @reader.first
      end

      it 'should return the correctly typed result' do
        @values.first.should.be.kind_of(Date)
      end

      it 'should return the correct result' do
        @values.first.should == Date.civil(2008, 2, 14)
      end

    end

    describe 'with manual typecasting a nil value' do

      before do
        @reader = @connection.query("SELECT release_date FROM widgets WHERE id = ?", 7)
        @reader.set_types(Date)
        @values = @reader.first
      end

      it 'should return a nil class' do
        @values.first.should.be.kind_of(NilClass)
      end

      it 'should return nil' do
       @values.first.should.be.nil
      end

    end

  end

  describe 'writing an Date' do

    before do
      @reader = @connection.query("SELECT id FROM widgets WHERE release_date = ? ORDER BY id", Date.civil(2008, 2, 14))
      @values = @reader.first
    end

    it 'should return the correct entry' do
      #Some of the drivers starts autoincrementation from 0 not 1
      @values.first.should.satisfy { |val| val == 1 or val == 0 }
    end

  end

end

shared 'supporting Date autocasting' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a Date' do

    describe 'with automatic typecasting' do

      before do
        @reader = @connection.query("SELECT release_date FROM widgets WHERE ad_description = ?", 'Buy this product now!')
        @values = @reader.first
      end

      it 'should return the correctly typed result' do
        @values.first.should.be.kind_of(Date)
      end

      it 'should return the correct result' do
        @values.first.should == Date.civil(2008, 2, 14)
      end

    end

  end

end
