shared_examples_for 'supporting Time' do

  before :all do
    setup_test_environment
  end

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
        @values.first.should be_kind_of(Time)
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
        @values.first.should be_kind_of(NilClass)
      end

      it 'should return nil' do
        @values.first.should be_nil
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
       @values.first.should satisfy { |val| val == 1 or val == 0 }
    end

  end

end

shared_examples_for 'supporting sub second Time' do

  before :all do
    setup_test_environment
  end

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
    @connection.create_command(<<-EOF).execute_non_query(Time.parse('2010-12-15 14:32:08.49377-08'))
      update widgets set release_timestamp = ? where id = 1
    EOF
    @connection.create_command(<<-EOF).execute_non_query(Time.parse('2010-12-15 14:32:28.942694-08'))
      update widgets set release_timestamp = ? where id = 2
    EOF

    @command = @connection.create_command("SELECT release_timestamp FROM widgets WHERE id < ? order by id")
    @command.set_types(Time)
    @reader = @command.execute_reader(3)
    @reader.next!
    @values = @reader.values
  end

  after do
    @connection.close
  end

  it 'should handle variable subsecond lengths properly' do
    @values.first.to_f.should be_within(0.00002).of(Time.at(1292452328, 493770).to_f)
    @reader.next!
    @values = @reader.values
    @values.first.to_f.should be_within(0.00002).of(Time.at(1292452348, 942694).to_f)
  end

end
