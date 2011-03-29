# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/shared/typecast/float_spec'

describe 'DataObjects::Oracle with Float' do
  it_should_behave_like 'supporting Float'
  # it_should_behave_like 'supporting Float autocasting'
end

describe 'DataObjects::Oracle with Float supporting Float autocasting' do

  include DataObjectsSpecHelpers

  before :all do
    setup_test_environment
  end

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a Float' do

    describe 'with automatic typecasting' do

      before  do
        @reader = @connection.create_command("SELECT weight, cost1 FROM widgets WHERE ad_description = ?").execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correctly typed result' do
        @values.first.should be_kind_of(Float)
        @values.last.should be_kind_of(Float)
      end

      it 'should return the correct result' do
        @values.first.should be_close(13.4, 0.000001)
        @values.last.should be_close(10.23, 0.000001)
      end

    end

  end

end
