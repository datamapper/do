shared 'supporting Boolean' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a Boolean' do

    describe 'with manual typecasting' do

      before do
        @reader = @connection.query("SELECT flags FROM widgets WHERE ad_description = ?", 'Buy this product now!')
        @reader.set_types(TrueClass)
        @values = @reader.first
      end

      it 'should return the correctly typed result' do
        @values.first.should.be.kind_of(FalseClass)
      end

      it 'should return the correct result' do
        @values.first.should == false
      end

    end

    describe 'with manual typecasting a true value' do

      before do
        @reader = @connection.query("SELECT flags FROM widgets WHERE id = ?", 2)
        @reader.set_types(TrueClass)
        @values = @reader.first
      end

      it 'should return the correctly typed result' do
        @values.first.should.be.kind_of(TrueClass)
      end

      it 'should return the correct result' do
       @values.first.should.be.true
      end

    end

    describe 'with manual typecasting a nil value' do

      before do
        @reader = @connection.query("SELECT flags FROM widgets WHERE id = ?", 4)
        @reader.set_types(TrueClass)
        @values = @reader.first
      end

      it 'should return the correctly typed result' do
        @values.first.should.be.kind_of(NilClass)
      end

      it 'should return the correct result' do
       @values.first.should.be.nil
      end

    end

  end

  describe 'writing an Boolean' do

    before do
      @reader = @connection.query("SELECT id FROM widgets WHERE flags = ?", true)
      @values = @reader.first
    end

    it 'should return the correct entry' do
      @values.first.should == 2
    end

  end

end

shared 'supporting Boolean autocasting' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a Boolean' do

    describe 'with automatic typecasting' do

      before do
        @reader = @connection.query("SELECT flags FROM widgets WHERE ad_description = ?", 'Buy this product now!')
        @values = @reader.first
      end

      it 'should return the correctly typed result' do
        @values.first.should.be.kind_of(FalseClass)
      end

      it 'should return the correct result' do
        @values.first.should == false
      end

    end

  end

end
