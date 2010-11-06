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
      @reader = @connection.query("SELECT ad_description FROM widgets WHERE ad_description = ?", 'Buy this product now!')
      @reader.set_types(::CustomTextType)
      @values = @reader.first
    end

    it 'should return the correct entry' do
      @values.first.should == 'Buy this product now!'
    end

  end

end
