shared_examples_for 'supporting Date' do

  before :all do
    setup_test_environment
  end

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a Date' do

    describe 'with manual typecasting' do

      before do
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

    describe 'with manual typecasting a nil value' do

      before do
        @command = @connection.create_command("SELECT release_date FROM widgets WHERE id = ?")
        @command.set_types(Date)
        @reader = @command.execute_reader(7)
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return a nil class' do
        @values.first.should be_kind_of(NilClass)
      end

      it 'should return nil' do
       @values.first.should be_nil
      end

    end

  end

  describe 'writing an Date' do

    before do
      @reader = @connection.create_command("SELECT id FROM widgets WHERE release_date = ? ORDER BY id").execute_reader(Date.civil(2008, 2, 14))
      @reader.next!
      @values = @reader.values
    end

    after do
      @reader.close
    end

    it 'should return the correct entry' do
      #Some of the drivers starts autoincrementation from 0 not 1
      @values.first.should satisfy { |val| val == 1 or val == 0 }
    end

  end

end

shared_examples_for 'supporting Date autocasting' do

  before :all do
    setup_test_environment
  end

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a Date' do

    describe 'with automatic typecasting' do

      before do
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
