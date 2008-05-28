require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataObjects::Jdbc" do

  it "should connect successfully via TCP"
  it "should connect successfully via the socket file"
  it "should return the current character set"
  it "should support changing the character set"

end

describe "DataObjects::Jdbc::Connection" do

  it "should be able to create a command" do
    #@connection = DataObjects::Jdbc::Connection.new("jdbc://postgres:pg123@localhost:5432/do_jdbc_test?driver=org.postgresql.Driver&protocol=postgresql")
    @connection = DataObjects::Jdbc::Connection.new("jdbc:derby:firstdb")

    command = @connection.create_command("SELECT id, name FROM users")
    command.set_types [Integer, String]
    command.should be_kind_of(DataObjects::Jdbc::Command)
    command.instance_variable_get("@types").should == [Integer, String]
  end

  it "should return a Result" do
    #@connection = DataObjects::Jdbc::Connection.new("jdbc://postgres:pg123@localhost:5432/do_jdbc_test?driver=org.postgresql.Driver&protocol=postgresql")
    @connection = DataObjects::Jdbc::Connection.new("jdbc:hsqldb:mem;driver=org.hsqldb.jdbcDriver")

    command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')")
    result = command.execute_non_query
    result.should be_kind_of(DataObjects::Jdbc::Result)
  end

  it "should be able to determine the affected_rows" do
    @connection = DataObjects::Jdbc::Connection.new("jdbc://postgres:pg123@localhost:5432/do_jdbc_test?driver=org.postgresql.Driver&protocol=postgresql")

    command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')")
    result = command.execute_non_query
    result.to_i.should == 1
  end

end
