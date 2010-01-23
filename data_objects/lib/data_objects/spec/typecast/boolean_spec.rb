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
        @command = @connection.create_command("SELECT flags FROM widgets WHERE ad_description = ?")
        @command.set_types(TrueClass)
        @reader = @command.execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
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
        @command = @connection.create_command("SELECT flags FROM widgets WHERE id = ?")
        @command.set_types(TrueClass)
        @reader = @command.execute_reader(2)
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
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
        @command = @connection.create_command("SELECT flags FROM widgets WHERE id = ?")
        @command.set_types(TrueClass)
        @reader = @command.execute_reader(4)
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

  describe 'writing an Boolean' do

    before do
      @reader = @connection.create_command("SELECT id FROM widgets WHERE flags = ?").execute_reader(true)
      @reader.next!
      @values = @reader.values
    end

    after do
      @reader.close
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
        @reader = @connection.create_command("SELECT flags FROM widgets WHERE ad_description = ?").execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
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
