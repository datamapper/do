require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataObjects::Jdbc" do

  it "should connect successfully via TCP"
  it "should connect successfully via the socket file"
  it "should return the current character set"
  it "should support changing the character set"

end

describe "DataObjects::Jdbc::Connection" do

  before(:all) do
    @connection = DataObjects::Connection.new("jdbc:hsqldb:mem")
  end

  it "should be able to create a command" do
    command = @connection.create_command("SELECT id, name FROM users")
    command.set_types [Integer, String]
    command.should be_kind_of(DataObjects::Jdbc::Command)
    command.instance_variable_get("@types").should == [Integer, String]
  end

  it "should be closeable" do
    #@connection.real_close
  end

  it "should raise an error for a bad query" do
    command = @connection.create_command("INSER INTO table_which_doesnt_exist (id) VALUES (1)")
    command.execute_non_query
    #command.execute_reader
    lambda { command.execute_non_query }.should raise_error('near "INSER": syntax error')

    command = @connection.create_command("INSERT INTO table_which_doesnt_exist (id) VALUES (1)")
    lambda { command.execute_non_query }.should raise_error("no such table: table_which_doesnt_exist")

    command = @connection.create_command("SELECT * FROM table_which_doesnt_exist")
    #lambda { command.execute_reader }.should raise_error("no such table: table_which_doesnt_exist")
  end

  it "should return a Result" do

    command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')")
    result = command.execute_non_query
    result.should be_kind_of(DataObjects::Jdbc::Result)
  end

  it "should be able to determine the affected_rows" do

    command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')")
    result = command.execute_non_query
    result.to_i.should == 1
  end

end
