# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/result_spec'

describe DataObjects::Postgres::Result do
  it_should_behave_like 'a Result'

  before :all do
    setup_test_environment
  end

  describe 'without using RETURNING' do

    before :each do
      @connection = DataObjects::Connection.new(CONFIG.uri)
      @result    = @connection.create_command("INSERT INTO users (name) VALUES (?)").execute_non_query("monkey")
    end

    after :each do
      @connection.close
    end

    it { @result.should respond_to(:affected_rows) }

    describe 'affected_rows' do

      it 'should return the number of created rows' do
        @result.affected_rows.should == 1
      end

    end

    it { @result.should respond_to(:insert_id) }

    describe 'insert_id' do

      it 'should return nil' do
        @result.insert_id.should be_nil
      end

      it 'should be retrievable through curr_val' do
        # This is actually the 4th record inserted
        reader = @connection.create_command("SELECT currval('users_id_seq')").execute_reader
        reader.next!
        reader.values.first.should == 4
      end

    end

  end

  describe 'when using RETURNING' do

    before :each do
      @connection = DataObjects::Connection.new(CONFIG.uri)
      @result    = @connection.create_command("INSERT INTO users (name) VALUES (?) RETURNING id").execute_non_query("monkey")
    end

    after :each do
      @connection.close
    end

    it { @result.should respond_to(:affected_rows) }

    describe 'affected_rows' do

      it 'should return the number of created rows' do
        @result.affected_rows.should == 1
      end

    end

    it { @result.should respond_to(:insert_id) }

    describe 'insert_id' do

      it 'should return the generated key value' do
        @result.insert_id.should == 2
      end

    end

  end

end
