shared 'supporting Float' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a Float' do

    describe 'with manual typecasting' do

      before do
        @command = @connection.create_command("SELECT id FROM widgets WHERE ad_description = ?")
        @command.set_types(Float)
        @reader = @command.execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correctly typed result' do
        @values.first.should.be.kind_of(Float)
      end

      it 'should return the correct result' do
       #Some of the drivers starts autoincrementation from 0 not 1
       @values.first.should.satisfy { |val| val == 1.0 or val == 0.0 }
      end

    end

    describe 'with manual typecasting a nil' do

      before do
        @command = @connection.create_command("SELECT cost1 FROM widgets WHERE id = ?")
        @command.set_types(Float)
        @reader = @command.execute_reader(5)
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correctly typed result' do
        @values.first.should.be.kind_of(NilClass)
      end

      it 'should return the correct result' do
       @values.first.should.be.nil
      end

    end
  end

  describe 'writing an Float' do

    before do
      @reader = @connection.create_command("SELECT id FROM widgets WHERE id = ?").execute_reader(2.0)
      @reader.next!
      @values = @reader.values
    end

    after do
      @reader.close
    end

    it 'should return the correct entry' do
       #Some of the drivers starts autoincrementation from 0 not 1
       @values.first.should.satisfy { |val| val == 1 or val == 2 }
    end

  end

end

shared 'supporting Float autocasting' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a Float' do

    describe 'with automatic typecasting' do

      before do
        @reader = @connection.create_command("SELECT weight, cost1 FROM widgets WHERE ad_description = ?").execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correctly typed result' do
        @values.first.should.be.kind_of(Float)
        @values.last.should.be.kind_of(Float)
      end

      it 'should return the correct result' do
        @values.first.should == 13.4
        BigDecimal.new(@values.last.to_s).round(2).should == 10.23
      end

    end

  end

end
