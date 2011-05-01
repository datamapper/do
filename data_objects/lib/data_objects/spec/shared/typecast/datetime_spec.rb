JRUBY = RUBY_PLATFORM =~ /java/ unless defined?(JRUBY)

shared_examples_for 'supporting DateTime' do

  before :all do
    setup_test_environment
  end

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a DateTime' do

    describe 'with manual typecasting' do

      before do
        @command = @connection.create_command("SELECT release_datetime FROM widgets WHERE ad_description = ?")
        @command.set_types(DateTime)
        @reader = @command.execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correctly typed result' do
        @values.first.should be_kind_of(DateTime)
      end

      it 'should return the correct result' do
        date = @values.first
        local_offset = Rational(Time.local(2008, 2, 14).utc_offset, 86400)
        date.should == DateTime.civil(2008, 2, 14, 00, 31, 12, local_offset)
      end

    end

    describe 'with manual typecasting a nil value' do

      before do
        @command = @connection.create_command("SELECT release_datetime FROM widgets WHERE id = ?")
        @command.set_types(DateTime)
        @reader = @command.execute_reader(8)
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

    describe 'with manual typecasting a datetime column' do

      before do
        @command = @connection.create_command("SELECT release_datetime FROM widgets WHERE id = ? OR id = ? ORDER BY id")
        @command.set_types(DateTime)
        @reader = @command.execute_reader(1, 10)
        @reader.next!
        @feb_row = @reader.values
        @reader.next!
        @jul_row = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correct offset in Feb' do
        (@feb_row.first.offset * 86400).to_i.should == Time.local(2008, 2, 14, 0, 31, 12).utc_offset
      end

      it 'should return the correct offset in Jul' do
        (@jul_row.first.offset * 86400).to_i.should == Time.local(2008, 7, 14, 0, 31, 12).utc_offset
      end

    end

  end

  describe 'writing an DateTime' do

    before do
      local_offset = Rational(Time.local(2008, 2, 14).utc_offset, 86400)
      @reader = @connection.create_command("SELECT id FROM widgets WHERE release_datetime = ? ORDER BY id").execute_reader(DateTime.civil(2008, 2, 14, 00, 31, 12, local_offset))
      @reader.next!
      @values = @reader.values
    end

    after do
      @reader.close
    end

    it 'should return the correct entry' do
      #Some of the drivers starts autoincrementation from 0 not 1
      @values.first.should satisfy { |val| val == 0 or val == 1 }
    end

  end

end

shared_examples_for 'supporting DateTime autocasting' do

  before :all do
    setup_test_environment
  end

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a DateTime' do

    describe 'with automatic typecasting' do

      before do
        @reader = @connection.create_command("SELECT release_datetime FROM widgets WHERE ad_description = ?").execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correctly typed result' do
        @values.first.should be_kind_of(DateTime)
      end

      it 'should return the correct result' do
        @values.first.should == Time.local(2008, 2, 14, 00, 31, 12).send(:to_datetime)
      end

    end

  end

end
