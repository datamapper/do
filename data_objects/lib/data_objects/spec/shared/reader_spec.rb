shared_examples_for 'a Reader' do

  before :all do
    setup_test_environment
  end

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

  it { @reader.should respond_to(:fields) }

  describe 'fields' do

    it 'should return the correct fields in the reader' do
      # we downcase the field names as some drivers such as do_derby, do_h2,
      # do_hsqldb, do_oracle return the field names as uppercase
      @reader.fields.should be_array_case_insensitively_equal_to(['code', 'name'])
    end

    it 'should return the field alias as the name, when the SQL AS keyword is specified' do
      reader = @connection.create_command("SELECT code AS codigo, name AS nombre FROM widgets WHERE ad_description = ? order by id").execute_reader('Buy this product now!')
      reader.fields.should_not be_array_case_insensitively_equal_to(['code',   'name'])
      reader.fields.should     be_array_case_insensitively_equal_to(['codigo', 'nombre'])
      reader.close
    end

  end

  it { @reader.should respond_to(:values) }

  describe 'values' do

    describe 'when the reader is uninitialized' do

      it 'should raise an error' do
        expect { @reader.values }.to raise_error(DataObjects::DataError)
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
        expect { @reader.values }.to raise_error(DataObjects::DataError)
      end
    end

  end

  it { @reader.should respond_to(:close) }

  describe 'close' do

    describe 'on an open reader' do

      it 'should return true' do
        @reader.close.should be_true
      end

    end

    describe 'on an already closed reader' do

      before do
        @reader.close
      end

      it 'should return false' do
        @reader.close.should be_false
      end

    end

  end

  it { @reader.should respond_to(:next!) }

  describe 'next!' do

    describe 'successfully moving the cursor initially' do

      it 'should return true' do
        @reader.next!.should be_true
      end

    end

    describe 'moving the cursor' do

      before do
        @reader.next!
      end

      it 'should move the cursor to the next value' do
        @reader.values.should == ["W0000001", "Widget 1"]
        lambda { @reader.next! }.should change { @reader.values }
        @reader.values.should == ["W0000002", "Widget 2"]
      end

    end

    describe 'arriving at the end of the reader' do

      before do
        while @reader.next!; end
      end

      it 'should return false when the end is reached' do
        @reader.next!.should be_false
      end

    end

  end

  it { @reader.should respond_to(:field_count) }

  describe 'field_count' do

    it 'should count the number of fields' do
      @reader.field_count.should == 2
    end

  end

  it { @reader.should respond_to(:values) }

  describe 'each' do

    it 'should yield each row to the block for multiple columns' do
      rows_yielded = 0
      @reader.each do |row|
        row.should respond_to(:[])

        row.size.should == 2

        # the field names need to be case insensitive as some drivers such as
        # do_derby, do_h2, do_hsqldb return the field names as uppercase
        (row['name'] || row['NAME']).should be_kind_of(String)
        (row['code'] || row['CODE']).should be_kind_of(String)

        rows_yielded += 1
      end
      rows_yielded.should == 15
    end

    it 'should yield each row to the block for a single column' do
      rows_yielded = 0
      @reader2.each do |row|
        row.should respond_to(:[])

        row.size.should == 1

        # the field names need to be case insensitive as some drivers such as
        # do_derby, do_h2, do_hsqldb return the field names as uppercase
        (row['code'] || row['CODE']).should be_kind_of(String)

        rows_yielded += 1
      end
      rows_yielded.should == 15
    end

    it 'should return the reader' do
      @reader.each { |row| }.should equal(@reader)
    end

  end

end
