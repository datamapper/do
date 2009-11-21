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
        @command = @connection.create_command("SELECT release_date FROM widgets WHERE ad_description = ?")
        @command.set_types(Time)
        @reader = @command.execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
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
        @command = @connection.create_command("SELECT release_timestamp FROM widgets WHERE id = ?")
        @command.set_types(Time)
        @reader = @command.execute_reader(9)
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
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
      @reader = @connection.create_command("SELECT id FROM widgets WHERE release_datetime = ? ORDER BY id").execute_reader(Time.local(2008, 2, 14, 00, 31, 12))
      @reader.next!
      @values = @reader.values
    end

    after do
      @reader.close
    end

    it 'should return the correct entry' do
       #Some of the drivers starts autoincrementation from 0 not 1
       @values.first.should.satisfy { |val| val == 1 or val == 0 }
    end

  end

end
