shared 'supporting Time' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a Time' do

    describe 'with manual typecasting' do

      before do
        @reader = @connection.query("SELECT release_date FROM widgets WHERE ad_description = ?", 'Buy this product now!')
        @reader.set_types(Time)
        @values = @reader.first
      end

      it 'should return the correctly typed result' do
        @values.first.should.be.kind_of(Time)
      end

      it 'should return the correct result' do
        @values.first.should == Time.local(2008, 2, 14)
      end

    end

    describe 'with manual typecasting a nil value' do

      before do
        @reader = @connection.query("SELECT release_timestamp FROM widgets WHERE id = ?", 9)
        @reader.set_types(Time)
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

  describe 'writing an Time' do

    before do
      @reader = @connection.query("SELECT id FROM widgets WHERE release_datetime = ? ORDER BY id", Time.local(2008, 2, 14, 00, 31, 12))
      @values = @reader.first
    end

    it 'should return the correct entry' do
       #Some of the drivers starts autoincrementation from 0 not 1
       @values.first.should.satisfy { |val| val == 1 or val == 0 }
    end

  end

end
