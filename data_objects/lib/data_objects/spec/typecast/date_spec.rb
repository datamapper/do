share_examples_for 'supporting Date' do

  include DataObjectsSpecHelpers

  before :all do
    setup_test_environment
  end

  before :each do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after :each do
    @connection.close
  end

  describe 'reading a Date' do

    describe 'with manual typecasting' do

      before  do
        @command = @connection.create_command("SELECT release_datetime FROM widgets WHERE ad_description = ?")
        @command.set_types(Date)
        @reader = @command.execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correctly typed result' do
        @values.first.should be_kind_of(Date)
      end

      it 'should return the correct result' do
        @values.first.should == Date.civil(2008, 2, 14)
      end

    end

  end

  describe 'writing an Date' do

    before  do
      @reader = @connection.create_command("SELECT id FROM widgets WHERE release_date = ?").execute_reader(Date.civil(2008, 2, 14))
      @reader.next!
      @values = @reader.values
    end

    after do
      @reader.close
    end

    it 'should return the correct entry' do
      @values.first.should == 1
    end
    
  end

end

share_examples_for 'supporting Date autocasting' do

  include DataObjectsSpecHelpers

  before :all do
    setup_test_environment
  end

  before :each do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after :each do
    @connection.close
  end

  describe 'reading a Date' do

    describe 'with automatic typecasting' do

      before  do
        @reader = @connection.create_command("SELECT release_date FROM widgets WHERE ad_description = ?").execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correctly typed result' do
        @values.first.should be_kind_of(Date)
      end

      it 'should return the correct result' do
        @values.first.should == Date.civil(2008, 2, 14)
      end

    end

  end

end