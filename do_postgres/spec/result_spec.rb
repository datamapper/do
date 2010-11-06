# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/result_spec'

describe DataObjects::Postgres::Result do
  behaves_like 'a Result'

  after do
    setup_test_environment
  end

  describe 'without using RETURNING' do

    before do
      @connection = DataObjects::Connection.new(CONFIG.uri)
      @result    = @connection.execute("INSERT INTO users (name) VALUES (?)", "monkey")
    end

    after do
      @connection.close
    end

    it 'should respond to #affected_rows' do @result.should.respond_to(:affected_rows) end

    describe 'affected_rows' do

      it 'should return the number of created rows' do
        @result.affected_rows.should == 1
      end

    end

    it 'should respond to #insert_id' do @result.should.respond_to(:insert_id) end

    describe 'insert_id' do

      it 'should return nil' do
        @result.insert_id.should.be.nil
      end

      it 'should be retrievable through curr_val' do
        reader = @connection.query("SELECT currval('users_id_seq')")
        reader.first.first.should == 2
      end

    end

  end

  describe 'when using RETURNING' do

    before do
      @connection = DataObjects::Connection.new(CONFIG.uri)
      @result    = @connection.execute("INSERT INTO users (name) VALUES (?) RETURNING id", "monkey")
    end

    after do
      @connection.close
    end

    it 'should respond to #affected_rows' do @result.should.respond_to(:affected_rows) end

    describe 'affected_rows' do

      it 'should return the number of created rows' do
        @result.affected_rows.should == 1
      end

    end

    it 'should respond to #insert_id' do @result.should.respond_to(:insert_id) end

    describe 'insert_id' do

      it 'should return the generated key value' do
        @result.insert_id.should == 2
      end

    end

  end

end
