shared 'a Reader' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
    @reader     = @connection.query("SELECT code, name FROM widgets WHERE ad_description = ? order by id", 'Buy this product now!')
    @reader2    = @connection.query("SELECT code FROM widgets WHERE ad_description = ? order by id", 'Buy this product now!')
  end

  after do
    @connection.close
  end

  it 'should respond to #columns' do @reader.should.respond_to(:columns) end

  describe 'columns' do

    def array_case_insensitively_equal_to(arr)
      lambda { |obj| obj.map { |f| f.downcase } == arr }
    end

    it 'should return the correct fields in the reader' do
      # do_hsqldb, do_oracle return the field names as uppercase
      @reader.columns.should.be array_case_insensitively_equal_to(['code', 'name'])
    end

  end

  it 'should respond to #column_count' do @reader.should.respond_to(:column_count) end

  describe 'column_count' do

    it 'should count the number of columns' do
      @reader.column_count.should == 2
    end

  end

  it 'should respond to #types' do @reader.should.respond_to(:types) end

  describe 'types' do

    def array_case_insensitively_equal_to(arr)
      lambda { |obj| obj.map { |f| f.downcase } == arr }
    end

    it 'should return the correct types in the reader' do
      # do_hsqldb, do_oracle return the field names as uppercase
      @reader.types.should.be == [String, String]
    end

  end

  it 'should respond to #row_count' do @reader.should.respond_to(:row_count) end

  describe 'row_count' do

    it 'should count the number of rows' do
      @reader.row_count.should == 15
    end

  end

  it 'should respond to #each' do @reader.should.respond_to(:each) end

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
