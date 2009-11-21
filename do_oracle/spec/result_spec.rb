# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/result_spec'

describe DataObjects::Oracle::Result do
  behaves_like 'a Result'
end

describe DataObjects::Oracle::Result do


  def current_sequence_value(seq_name)
    reader = @connection.create_command("SELECT #{seq_name}.currval FROM dual").execute_reader
    reader.next!
    value = reader.values.first
    reader.close
    value
  end

  setup_test_environment(false)

  describe 'without using RETURNING' do

    before do
      @connection = DataObjects::Connection.new(CONFIG.uri)
      @users_seq_value = current_sequence_value("users_seq")
      @result    = @connection.create_command("INSERT INTO users (name) VALUES (?)").execute_non_query("monkey")
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

      it 'should be retrievable through currval' do
        # This is actually the 2nd record inserted
        current_sequence_value("users_seq").should == @users_seq_value + 1
      end

    end

  end

  describe 'when using RETURNING' do

    before do
      @connection = DataObjects::Connection.new(CONFIG.uri)
      @users_seq_value = current_sequence_value("users_seq")
      @result    = @connection.create_command("INSERT INTO users (name) VALUES (?) RETURNING id INTO :insert_id").execute_non_query("monkey")
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
        @result.insert_id.should == @users_seq_value + 1
      end

    end

  end

end
