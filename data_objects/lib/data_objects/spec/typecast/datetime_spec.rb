JRUBY = RUBY_PLATFORM =~ /java/ unless defined?(JRUBY)

shared 'supporting DateTime' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a DateTime' do

    describe 'with manual typecasting' do

      before do
        @reader = @connection.query("SELECT release_date FROM widgets WHERE ad_description = ?", 'Buy this product now!')
        @reader.set_types(DateTime)
        @values = @reader.first
      end

      it 'should return the correctly typed result' do
        @values.first.should.be.kind_of(DateTime)
      end

      it 'should return the correct result' do
        date = @values.first
        Date.civil(date.year, date.mon, date.day).should == Date.civil(2008, 2, 14)
      end

    end

    describe 'with manual typecasting a nil value' do

      before do
        @reader = @connection.query("SELECT release_datetime FROM widgets WHERE id = ?", 8)
        @reader.set_types(DateTime)
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

  describe 'writing an DateTime' do

    before do
      local_offset = Rational(Time.local(2008, 2, 14).utc_offset, 86400)
      @reader = @connection.query("SELECT id FROM widgets WHERE release_datetime = ? ORDER BY id", DateTime.civil(2008, 2, 14, 00, 31, 12, local_offset))
      @values = @reader.first
    end

    it 'should return the correct entry' do
      #Some of the drivers starts autoincrementation from 0 not 1
      @values.first.should.satisfy { |val| val == 0 or val == 1 }
    end

  end

end

shared 'supporting DateTime autocasting' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a DateTime' do

    describe 'with automatic typecasting' do

      before do
        @reader = @connection.query("SELECT release_datetime FROM widgets WHERE ad_description = ?", 'Buy this product now!')
        @values = @reader.first
      end

      it 'should return the correctly typed result' do
        @values.first.should.be.kind_of(DateTime)
      end

      it 'should return the correct result' do
        pending('when this is fixed for DST issues')
        @values.first.should == Time.local(2008, 2, 14, 00, 31, 12).to_datetime
      end

    end

  end

end
