# encoding: utf-8

shared_examples_for 'supporting String' do

  before :all do
    setup_test_environment
  end

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a String' do

    describe 'with automatic typecasting' do

      before do
        @reader = @connection.create_command("SELECT code FROM widgets WHERE ad_description = ?").execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correctly typed result' do
        @values.first.should be_kind_of(String)
      end

      it 'should return the correct result' do
        @values.first.should == "W0000001"
      end

    end

    describe 'with manual typecasting' do

      before do
        @command = @connection.create_command("SELECT weight FROM widgets WHERE ad_description = ?")
        @command.set_types(String)
        @reader = @command.execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correctly typed result' do
        @values.first.should be_kind_of(String)
      end

      it 'should return the correct result' do
        @values.first.should == "13.4"
      end

    end

  end

  describe 'writing a String' do

    before do
      @reader = @connection.create_command("SELECT id FROM widgets WHERE id = ?").execute_reader("2")
      @reader.next!
      @values = @reader.values
    end

    after do
      @reader.close
    end

    it 'should return the correct entry' do
      # Some of the drivers starts autoincrementation from 0 not 1
      @values.first.should satisfy { |val| val == 1 or val == 2 }
    end

  end

  describe 'writing and reading a multibyte String' do

    ['Aslak Hellesøy',
     'Пётр Алексе́евич Рома́нов',
     '歐陽龍'].each do |name|

       before do
         # SQL Server Unicode String Literals
         @n = 'N' if defined?(DataObjects::SqlServer::Connection) && @connection.kind_of?(DataObjects::SqlServer::Connection)
       end

      it 'should write a multibyte String' do
        @command = @connection.create_command('INSERT INTO users (name) VALUES(?)')
        expect { @command.execute_non_query(name) }.not_to raise_error(DataObjects::DataError)
      end

      it 'should read back the multibyte String' do
        @command = @connection.create_command('SELECT name FROM users WHERE name = ?')
        @reader = @command.execute_reader(name)
        @reader.next!
        @reader.values.first.should == name
        @reader.close
      end

      it 'should write a multibyte String (without query parameters)' do
        @command = @connection.create_command("INSERT INTO users (name) VALUES(#{@n}\'#{name}\')")
        expect { @command.execute_non_query }.not_to raise_error(DataObjects::DataError)
      end

      it 'should read back the multibyte String (without query parameters)' do
        @command = @connection.create_command("SELECT name FROM users WHERE name = #{@n}\'#{name}\'")
        @reader = @command.execute_reader
        @reader.next!
        @reader.values.first.should == name
        @reader.close
      end

    end
  end

  class ::StringWithExtraPowers < String; end

  describe 'writing a kind of (subclass of) String' do

    before do
      @reader = @connection.create_command("SELECT id FROM widgets WHERE id = ?").execute_reader(::StringWithExtraPowers.new("2"))
      @reader.next!
      @values = @reader.values
    end

    after do
      @reader.close
    end

    it 'should return the correct entry' do
      # Some of the drivers starts autoincrementation from 0 not 1
      @values.first.should satisfy { |val| val == 1 or val == 2 }
    end

  end

end
