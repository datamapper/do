# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/shared/typecast/class_spec'

describe 'DataObjects::Openedge with Class' do

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

  describe 'reading a Class' do

    describe 'with manual typecasting' do

      before  do
        @command = @connection.create_command("SELECT class_name FROM widgets WHERE ad_description = ?")
        @command.set_types(Class)
        @reader = @command.execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correctly typed result' do
        @values.first.should be_kind_of(Class)
      end

      it 'should return the correct result' do
        @values.first.should == String
      end

    end

  end

  describe 'writing a Class' do

    before  do
      @reader = @connection.create_command("SELECT class_name FROM widgets WHERE class_name = ?").execute_reader(String)
      @reader.next!
      @values = @reader.values
    end

    after do
      @reader.close
    end

    it 'should return the correct entry' do
      @values.first.should == "String"
    end

  end

end
