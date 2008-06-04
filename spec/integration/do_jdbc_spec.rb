require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataObjects::Jdbc::Connection" do
  include JdbcSpecHelpers

  it "should connect to the database" do
    @connection = DataObjects::Connection.new("jdbc:hsqldb:mem")
  end

  it "should be closeable" do
    pending
    @connection = DataObjects::Connection.new("jdbc:hsqldb:mem")
    @connection.real_close.should_not raise_error
  end

end

describe "DataObjects::Jdbc::Command" do
  include JdbcSpecHelpers

  before(:all) do
    @connection = DataObjects::Connection.new("jdbc:hsqldb:mem")
  end

  it "should be able to create a command" do
    command = @connection.create_command("SELECT id, name FROM users")
    command.set_types [Integer, String]
    command.should be_kind_of(DataObjects::Jdbc::Command)
    command.instance_variable_get("@types").should == [Integer, String]
  end

  it "#execute_non_query should raise an error for a bad query" do
    command = @connection.create_command("INSER INTO table_which_doesnt_exist (id) VALUES (1)")
    lambda { command.execute_non_query }.should raise_error(JdbcError,
        /Unexpected token: INSER in statement \[INSER\]/)

    command = @connection.create_command("INSERT INTO table_which_doesnt_exist (id) VALUES (1)")
    lambda { command.execute_non_query }.should raise_error(JdbcError,
        /Table not found in statement \[INSERT INTO table_which_doesnt_exist\]/)
  end

  it "#execute_reader should raise an error for a bad query" do
    command = @connection.create_command("SELCT * FROM table_which_doesnt_exist")
    lambda { command.execute_reader }.should raise_error(JdbcError,
        /Unexpected token: SELCT in statement \[SELCT\]/)

    command = @connection.create_command("SELECT * FROM table_which_doesnt_exist")
    lambda { command.execute_reader }.should raise_error(JdbcError,
        /Table not found in statement \[SELECT \* FROM table_which_doesnt_exist\]/)
  end

  it "should create a table" do
    command = @connection.create_command(<<-EOF).execute_non_query
    CREATE TABLE invoices (
      id INTEGER IDENTITY, invoice_number VARCHAR(256), num_col INTEGER
      )
    EOF
  end

  it "should execute a non query and return a result" do
    command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')")
    result = command.execute_non_query
    result.should be_kind_of(DataObjects::Jdbc::Result)
  end
  
  it "should execute a query and return a reader" do
    pending "Not returning a Reader"
    command = @connection.create_command("SELECT * FROM invoices")
    reader = command.execute_reader
    reader.should be_kind_of(DataObjects::Jdbc::Reader)
  end

end

describe "DataObjects::Jdbc::Result" do
  include JdbcSpecHelpers

  before(:all) do
    @connection = DataObjects::Connection.new("jdbc:hsqldb:mem")
  end

  it "should be able to determine the affected_rows" do
    command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')")
    result = command.execute_non_query
    result.to_i.should == 1
  end

end

describe "DataObjects::Jdbc::Reader" do
  include JdbcSpecHelpers

end
