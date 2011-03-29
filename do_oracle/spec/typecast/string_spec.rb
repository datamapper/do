# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/shared/typecast/string_spec'

# describe 'DataObjects::Oracle with String' do
#   it_should_behave_like 'supporting String'
# end

describe 'DataObjects::Oracle with String' do

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

  describe 'reading a String' do

    describe 'with automatic typecasting' do

      before  do
        @reader = @connection.create_command("SELECT code FROM widgets WHERE ad_description = ?").execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correctly typed result' do
        @values.first.should be_kind_of(String)
      end

      it 'should return the correct result' do
        @values.first.should == "W0000001"
      end

    end

    describe 'with manual typecasting' do

      before  do
        @command = @connection.create_command("SELECT weight FROM widgets WHERE ad_description = ?")
        @command.set_types(String)
        @reader = @command.execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correctly typed result' do
        @values.first.should be_kind_of(String)
      end

      it 'should return the correct result' do
        @values.first.to_f.should be_close(13.4, 0.000001)
      end

    end

  end

  describe 'writing a String' do

    before  do
      @reader = @connection.create_command("SELECT id FROM widgets WHERE id = ?").execute_reader("2")
      @reader.next!
      @values = @reader.values
    end

    after do
      @reader.close
    end

    it 'should return the correct entry' do
      # Some of the drivers starts autoincrementation from 0 not 1
      @values.first.should satisfy { |val| val == 1 or val == 2 }
    end

  end

end

describe 'DataObjects::Oracle with Text' do

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

  describe 'reading a Text' do

    describe 'with automatic typecasting' do

      before  do
        @reader = @connection.create_command("SELECT whitepaper_text FROM widgets WHERE ad_description = ?").execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correctly typed result' do
        @values.first.should be_kind_of(String)
      end

      it 'should return the correct result' do
        @values.first.should == "1234567890"*500
      end

    end

  end

  describe 'inserting a short string to Text column' do

    before  do
      @result = @connection.create_command("INSERT INTO widgets (whitepaper_text) VALUES (?) RETURNING id INTO :insert_id").execute_non_query("short text")
      @reader = @connection.create_command("SELECT whitepaper_text FROM widgets WHERE id = ?").execute_reader(@result.insert_id)
      @reader.next!
      @values = @reader.values
    end

    after do
      @reader.close
    end

    it 'should return the correct entry' do
      @values.first.should == "short text"
    end

  end

  describe 'inserting a large text to Text column' do

    before  do
      @result = @connection.create_command("INSERT INTO widgets (whitepaper_text) VALUES (?) RETURNING id INTO :insert_id").
        execute_non_query("long text"*1000)
      @reader = @connection.create_command("SELECT whitepaper_text FROM widgets WHERE id = ?").execute_reader(@result.insert_id)
      @reader.next!
      @values = @reader.values
    end

    after do
      @reader.close
    end

    it 'should return the correct entry' do
      @values.first.should == "long text"*1000
    end

  end

end
