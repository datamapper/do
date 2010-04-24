shared 'a Reader' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
    @reader     = @connection.create_command("SELECT code, name FROM widgets WHERE ad_description = ? order by id").execute_reader('Buy this product now!')
    @reader2    = @connection.create_command("SELECT code FROM widgets WHERE ad_description = ? order by id").execute_reader('Buy this product now!')
  end

  after do
    @reader.close
    @reader2.close
    @connection.close
  end

  it 'should respond to #fields' do @reader.should.respond_to(:fields) end

  describe 'fields' do

    it 'should return the correct fields in the reader' do
      # we downcase the field names as some drivers such as do_derby, do_h2,
      # do_hsqldb return the field names as uppercase
      @reader.fields.map{ |f| f.downcase }.should == ['code', 'name']
    end

  end

  it 'should respond to #values' do @reader.should.respond_to(:values) end

  describe 'values' do

    describe 'when the reader is uninitialized' do

      it 'should raise an error' do
        should.raise(DataObjects::DataError) { @reader.values }
      end

    end

    describe 'when the reader is moved to the first result' do

      before do
        @reader.next!
      end

      it 'should return the correct first set of in the reader' do
        @reader.values.should == ["W0000001", "Widget 1"]
      end

    end

    describe 'when the reader is moved to the second result' do

      before do
        @reader.next!; @reader.next!
      end

      it 'should return the correct first set of in the reader' do
        @reader.values.should == ["W0000002", "Widget 2"]
      end

    end

    describe 'when the reader is moved to the end' do

      before do
        while @reader.next! ; end
      end

      it 'should raise an error again' do
        should.raise(DataObjects::DataError) { @reader.values }
      end
    end

  end

  it 'should respond to #close' do @reader.should.respond_to(:close) end

  describe 'close' do

    describe 'on an open reader' do

      it 'should return true' do
        @reader.close.should.be.true
      end

    end

    describe 'on an already closed reader' do

      before do
        @reader.close
      end

      it 'should return false' do
        @reader.close.should.be.false
      end

    end

  end

  it 'should respond to #next!' do @reader.should.respond_to(:next!) end

  describe 'next!' do

    describe 'successfully moving the cursor initially' do

      it 'should return true' do
        @reader.next!.should.be.true
      end

    end

    describe 'moving the cursor' do

      before do
        @reader.next!
      end

      it 'should move the cursor to the next value' do
        @reader.values.should == ["W0000001", "Widget 1"]
        lambda { @reader.next! }.should.change { @reader.values }
        @reader.values.should == ["W0000002", "Widget 2"]
      end

    end

    describe 'arriving at the end of the reader' do

      before do
        while @reader.next!; end
      end

      it 'should return false when the end is reached' do
        @reader.next!.should.be.false
      end

    end

  end

  it 'should respond to #field_count' do @reader.should.respond_to(:field_count) end

  describe 'field_count' do

    it 'should count the number of fields' do
      @reader.field_count.should == 2
    end

  end

  it 'should respond to #values' do @reader.should.respond_to(:values) end

  describe 'each' do

    it 'should yield each row to the block for multiple columns' do
      rows_yielded = 0
      @reader.each do |row|
        row.should.respond_to(:[])

        row.size.should == 2

        # the field names need to be case insensitive as some drivers such as
        # do_derby, do_h2, do_hsqldb return the field names as uppercase
        (row['name'] || row['NAME']).should.be.kind_of(String)
        (row['code'] || row['CODE']).should.be.kind_of(String)

        rows_yielded += 1
      end
      rows_yielded.should == 15
    end

    it 'should yield each row to the block for a single column' do
      rows_yielded = 0
      @reader2.each do |row|
        row.should.respond_to(:[])

        row.size.should == 1

        # the field names need to be case insensitive as some drivers such as
        # do_derby, do_h2, do_hsqldb return the field names as uppercase
        (row['code'] || row['CODE']).should.be.kind_of(String)

        rows_yielded += 1
      end
      rows_yielded.should == 15
    end

    it 'should return the reader' do
      @reader.each { |row| }.should.equal(@reader)
    end

  end

end
