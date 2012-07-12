# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/shared/result_spec'

# splitting the descibe into two separate declaration avoids
# concurrent execution of the "it_should_behave_like ....."
# needed by some databases (sqlite3)

describe DataObjects::Mysql::Result do
  it_should_behave_like 'a Result'
end

describe DataObjects::Mysql::Result do
  it_should_behave_like 'a Result which returns inserted key with sequences'
  it_should_behave_like 'a Result which returns nil without sequences'
end

describe DataObjects::Mysql::Result do

  describe 'insert_id' do

    before do
      setup_test_environment
      @connection = DataObjects::Connection.new(CONFIG.uri)
      # set the sequence to a value larger than SQL integer
      command = @connection.create_command('INSERT INTO stuff (id, value) VALUES (?,?)')
      command.execute_non_query(3_000_000_000, 'cow')
      # use the sequence to generate an id
      command = @connection.create_command('INSERT INTO stuff (value) VALUES (?)')
      @result = command.execute_non_query('monkey')
    end

    after do
      @connection.close
    end

    it 'should return the bigint id' do
      @result.insert_id.should == 3_000_000_001
    end

  end
end
