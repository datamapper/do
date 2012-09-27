# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/shared/typecast/bigdecimal_spec'

describe 'DataObjects::Openedge with BigDecimal' do
  it_should_behave_like 'supporting BigDecimal'
  #it_should_behave_like 'supporting BigDecimal autocasting'
end

describe 'supporting BigDecimal autocasting' do

  before :all do
    setup_test_environment
  end

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a BigDecimal' do

    describe 'with automatic typecasting' do

      before do
        @reader = @connection.create_command("SELECT cost2 FROM widgets WHERE ad_description = ?").execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correctly typed result' do
        @values.first.should be_kind_of(BigDecimal)
      end

# There is an error in the JDBC driver that truncates these results. See ProKB P187898:
# http://knowledgebase.progress.com/articles/Article/P187898
=begin
      it 'should return the correct result' do
        @values.first.should == 50.23
      end
=end
    end

  end

end
