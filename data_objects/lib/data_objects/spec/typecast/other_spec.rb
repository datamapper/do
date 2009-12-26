class ::CustomTextType

  def initialize(value)
    @value = value
  end

  def to_s
    @value.to_s
  end

end

shared 'supporting other (unknown) type' do

  setup_test_environment

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'writing an object of unknown type' do

    before do
      @command = @connection.create_command("SELECT whitepaper_text FROM widgets WHERE whitepaper_text = ?")
      @command.set_types(::CustomTextType)
      @reader = @command.execute_reader('String')
      @reader.next!
      @values = @reader.values
    end

    after do
      @reader.close
    end

    it 'should return the correct entry' do
      @values.first.should == 'String'
    end

  end

end
