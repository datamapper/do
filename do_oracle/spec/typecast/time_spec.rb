# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/typecast/time_spec'

describe 'DataObjects::Oracle with Time' do

  include DataObjectsSpecHelpers

  before :all do
    unless JRUBY # if MRI then need to set TZ explicitly as otherwise DST might not work
      @orig_config_uri = CONFIG.uri
      @orig_time_zone = ENV['TZ']
      ENV['TZ'] = 'EET'
      CONFIG.uri += "?time_zone=#{ENV['TZ']}"
    end
    setup_test_environment
  end
  
  after :all do
    unless JRUBY
      CONFIG.uri = @orig_config_uri
      ENV['TZ'] = @orig_time_zone
    end
  end

  before :each do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after :each do
    @connection.close
  end

  describe 'reading a Time' do

    describe 'with manual typecasting' do

      before  do
        @command = @connection.create_command("SELECT release_date FROM widgets WHERE ad_description = ?")
        @command.set_types(Time)
        @reader = @command.execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correctly typed result' do
        @values.first.should be_kind_of(Time)
      end

      it 'should return the correct result' do
        @values.first.should == Time.local(2008, 2, 14)
      end

    end

  end

  describe 'writing an Time' do

    before  do
      @reader = @connection.create_command("SELECT id FROM widgets WHERE release_datetime = ? ORDER BY id").execute_reader(Time.local(2008, 2, 14, 00, 31, 12))
      @reader.next!
      @values = @reader.values
    end

    after do
      @reader.close
    end

    it 'should return the correct entry' do
       #Some of the drivers starts autoincrementation from 0 not 1
       @values.first.should satisfy { |val| val == 1 or val == 0 }
    end

  end

end

describe 'DataObjects::Oracle with Time' do

  include DataObjectsSpecHelpers

  before :all do
    setup_test_environment
  end

  before :each do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after :each do
    @connection.close
  end

  describe 'reading a Time' do

    describe 'with automatic typecasting' do

      before  do
        @reader = @connection.create_command("SELECT release_datetime FROM widgets WHERE ad_description = ?").execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correctly typed result' do
        @values.first.should be_kind_of(Time)
      end

      it 'should return the correct result' do
        @values.first.should == Time.local(2008, 2, 14, 00, 31, 12)
      end

    end

  end

end

describe 'DataObjects::Oracle session time zone' do

  after :each do
    @connection.close
  end

  describe 'set from environment' do

    before :each do
      # pending "set TZ environment shell variable before running this test" unless ENV['TZ']
      @connection = DataObjects::Connection.new(CONFIG.uri)
    end

    it "should have time zone from environment" do
      @reader = @connection.create_command("SELECT sessiontimezone FROM dual").execute_reader
      @reader.next!
      @reader.values.first.should == ENV['TZ']
    end

  end

  describe "set with connection string option" do

    before(:each) do
      @connection = DataObjects::Connection.new(CONFIG.uri+"?time_zone=CET")
    end

    it "should have time zone from connection option" do
      @reader = @connection.create_command("SELECT sessiontimezone FROM dual").execute_reader
      @reader.next!
      @reader.values.first.should == 'CET'
    end

  end

end
