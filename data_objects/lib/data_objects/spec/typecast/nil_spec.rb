shared 'supporting Nil' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a Nil' do

    describe 'with manual typecasting' do

      before do
        @reader = @connection.query("SELECT flags FROM widgets WHERE ad_description = ?", 'Buy this product now!')
        @reader.set_types(NilClass)
        @values = @reader.first
      end

      it 'should return the correctly typed result' do
        @values.first.should.be.kind_of(NilClass)
      end

      it 'should return the correct result' do
        @values.first.should == nil
      end

    end

  end

end

shared 'supporting writing an Nil' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end


   describe 'supporting writing an Nil' do
    # see as an example oracle
    # http://download.oracle.com/docs/cd/B19306_01/server.102/b14200/sql_elements005.htm#sthref487
    # http://download.oracle.com/docs/cd/B19306_01/server.102/b14200/conditions013.htm#i1050801

    describe 'as a parameter' do

      before do
        @reader = @connection.query("SELECT id FROM widgets WHERE ad_description IN (?) ORDER BY id", nil)
        @values = @reader.first
      end

      it 'should return the correct entry' do
        @values.should.not.be.nil
      end

    end

  end

end

shared 'supporting Nil autocasting' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a Nil' do

    describe 'with automatic typecasting' do

      before do
        @reader = @connection.query("SELECT ad_description FROM widgets WHERE id = ?", 3)
        @values = @reader.first
      end

      it 'should return the correctly typed result' do
        @values.first.should.be.kind_of(NilClass)
      end

      it 'should return the correct result' do
        @values.first.should == nil
      end

    end

  end

end
