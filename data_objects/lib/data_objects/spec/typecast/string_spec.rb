# encoding: utf-8

shared 'supporting String' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a String' do

    describe 'with automatic typecasting' do

      before do
        @reader = @connection.query("SELECT code FROM widgets WHERE ad_description = ?", 'Buy this product now!')
        @values = @reader.first
      end

      it 'should return the correctly typed result' do
        @values.first.should.be.kind_of(String)
      end

      it 'should return the correct result' do
        @values.first.should == "W0000001"
      end

    end

    describe 'with manual typecasting' do

      before do
        @reader = @connection.query("SELECT weight FROM widgets WHERE ad_description = ?", 'Buy this product now!')
        @reader.set_types(String)
        @values = @reader.first
      end

      it 'should return the correctly typed result' do
        @values.first.should.be.kind_of(String)
      end

      it 'should return the correct result' do
        @values.first.should == "13.4"
      end

    end

  end

  describe 'writing a String' do

    before do
      @reader = @connection.query("SELECT id FROM widgets WHERE id = ?", "2")
      @values = @reader.first
    end

    it 'should return the correct entry' do
      # Some of the drivers starts autoincrementation from 0 not 1
      @values.first.should.satisfy { |val| val == 1 or val == 2 }
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
        should.not.raise(DataObjects::DataError) { @connection.execute('INSERT INTO users (name) VALUES(?)', name) }
      end

      it 'should read back the multibyte String' do
        @reader = @connection.query('SELECT name FROM users WHERE name = ?', name)
        @reader.first.first.should == name
      end

      it 'should write a multibyte String (without query parameters)' do
        should.not.raise(DataObjects::DataError) { @connection.execute("INSERT INTO users (name) VALUES(#{@n}\'#{name}\')") }
      end

      it 'should read back the multibyte String (without query parameters)' do
        @reader = @connection.query("SELECT name FROM users WHERE name = #{@n}\'#{name}\'")
        @reader.first.first.should == name
      end

    end
  end

  class ::StringWithExtraPowers < String; end

  describe 'writing a kind of (subclass of) String' do

    before do
      @reader = @connection.query("SELECT id FROM widgets WHERE id = ?", ::StringWithExtraPowers.new("2"))
      @values = @reader.first
    end

    it 'should return the correct entry' do
      # Some of the drivers starts autoincrementation from 0 not 1
      @values.first.should.satisfy { |val| val == 1 or val == 2 }
    end

  end

end
