# require File.dirname(__FILE__) + '/spec_helper'
require 'rubygems'
require File.dirname(__FILE__) + "/../../data_objects/lib/data_objects"
require 'date'
require 'do_sqlite3'


describe "DataObjects::Sqlite3::Result" do
  before(:all) do
    @connection = DataObjects::Connection.new("sqlite3://#{File.expand_path(File.dirname(__FILE__))}/test.db")
  end
  
  it "should return the affected rows and insert_id" do    
    command = @connection.create_command("DROP TABLE users")
    command.execute_non_query
    command = @connection.create_command("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
    result = command.execute_non_query
    command = @connection.create_command("INSERT INTO users (name) VALUES ('test')")    
    result = command.execute_non_query
    result.insert_id.should == 1
    result.to_i.should == 1
  end
  
  it "should use DO::Quoting.escape_sql with passed params" do
    command = @connection.create_command("INSERT INTO users (name) VALUES (?)")
    result = command.execute_non_query("John Doe")
    result.insert_id.should == 2
    result.to_i.should == 1
  end
  
  it "should do a reader query" do
    command = @connection.create_command("SELECT * FROM users")
    reader = command.execute_reader
    
    lambda { reader.values }.should raise_error
    
    while ( reader.next! )
      lambda { reader.values }.should_not raise_error
      reader.values.should be_a_kind_of(Array)
    end
    
    lambda { reader.values }.should raise_error
    
    reader.close
  end

  it "should do a paramaterized reader query" do
    command = @connection.create_command("SELECT * FROM users WHERE id = ?")
    reader = command.execute_reader(1)
    reader.next!
    
    reader.values[0].should == 1
    
    reader.next!

    lambda { reader.values }.should raise_error

    reader.close
  end
  
  it "should do a custom typecast reader" do
    command = @connection.create_command("SELECT name, id FROM users")
    command.set_types [String, String]
    reader = command.execute_reader
    
    while ( reader.next! )
      reader.fields.should == ["name", "id"]
      reader.values.each { |v| v.should be_a_kind_of(String) }
    end
    
    reader.close
    
  end
end