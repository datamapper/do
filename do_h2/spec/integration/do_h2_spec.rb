require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataObjects::H2::Connection" do
  include H2SpecHelpers

  it "should connect to the database" do
    @connection = DataObjects::Connection.new("jdbc:h2:mem")
  end

end

describe "DataObjects::H2::Command" do
  include H2SpecHelpers

  before(:all) do
    setup_test_environment
  end

  it "should be able to create a command" do
    command = @connection.create_command("SELECT id, name FROM users")
    command.set_types [Integer, String]
    command.should be_kind_of(DataObjects::H2::Command)
    command.instance_variable_get("@types").should == [Integer, String]
  end

  describe "#execute_non_query" do

    it "should raise an error when given a bad query" do
      command = @connection.create_command("INSER INTO table_which_doesnt_exist (id) VALUES (1)")
      lambda { command.execute_non_query }.should raise_error(H2Error,
          /Syntax error in SQL statement INSER\[\*\]/)

      command = @connection.create_command("INSERT INTO table_which_doesnt_exist (id) VALUES (1)")
      lambda { command.execute_non_query }.should raise_error(H2Error,
          /Table TABLE_WHICH_DOESNT_EXIST not found/)
    end

    it "should execute and return a Result" do
      command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')")
      result = command.execute_non_query
      result.should be_kind_of(DataObjects::H2::Result)
    end

  end

  describe "#execute_reader" do

    it "should raise an error when given a bad query" do
      command = @connection.create_command("SELCT * FROM table_which_doesnt_exist")
      lambda { command.execute_reader }.should raise_error(H2Error,
          /Syntax error in SQL statement SELCT\[\*\]/)

      command = @connection.create_command("SELECT * FROM table_which_doesnt_exist")
      lambda { command.execute_reader }.should raise_error(H2Error,
          /Table TABLE_WHICH_DOESNT_EXIST not found/)
    end

    it "should execute and return a Reader" do
      command = @connection.create_command("SELECT * FROM invoices")
      reader = command.execute_reader
      reader.should be_kind_of(DataObjects::H2::Reader)
      reader.close.should == true
    end

  end

end

describe "DataObjects::H2::Result" do
  include H2SpecHelpers

  before(:all) do
    setup_test_environment
  end

  it "should be able to determine affected_rows, when one row is affected" do
    command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')")
    result = command.execute_non_query
    result.to_i.should == 1
  end

  it "should yield the last inserted id" do
    @connection.create_command("DELETE FROM invoices").execute_non_query

    # for H2 the newly generated ids are starting at 2?

    result = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')").execute_non_query
    result.insert_id.should == 2

    result = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('3456')").execute_non_query
    result.insert_id.should == 3
  end

  it "should be able to determine affected_rows, when multiple rows are affected" do
    [
      "DELETE FROM invoices",
      "INSERT INTO invoices (invoice_number) VALUES ('1234')",
      "INSERT INTO invoices (invoice_number) VALUES ('1234')"
    ].each { |q| @connection.create_command(q).execute_non_query }

    result = @connection.create_command("UPDATE invoices SET invoice_number = '3456'").execute_non_query
    result.to_i.should == 2
  end

end

describe "DataObjects::H2::Reader" do
  include H2SpecHelpers

  before(:all) do
    setup_test_environment
  end

  it "should raise an error when you pass too many or too few types for the expected result set" do
    lambda {
      select("SELECT name, fired_at FROM users", [String, DateTime, Integer])
      }.should raise_error(H2Error, /Field-count mismatch. Expected 3 fields, but the query yielded 2/)
  end

  it "shouldn't raise an error when you pass NO types for the expected result set" do
    lambda { select("SELECT name, fired_at FROM users", nil) }.should_not raise_error(H2Error)
  end

  it "should return the proper number of fields" do
    id = insert("INSERT INTO users (name) VALUES ('Billy Bob')")
    select("SELECT id, name, fired_at FROM users WHERE id = ?", nil, id) do |reader|
      reader.fields.size.should == 3
    end
  end

  it "should return proper number of rows and fields using row_count and field_count" do
    command = @connection.create_command("SELECT * FROM widgets WHERE id = (SELECT max(id) FROM widgets)")
    reader = command.execute_reader
    reader.field_count.should == 20
    reader.row_count.should == 1
    reader.close
  end

  it "should raise an exception if .values is called after reading all available rows" do
    select("SELECT * FROM widgets LIMIT 2") do |reader|
      # select already calls next once for us
      reader.next!
      reader.next!

      lambda { reader.values }.should raise_error(H2Error)
    end
  end

  it "should fetch the proper number of rows" do
    ids = [
      insert("INSERT INTO users (name) VALUES ('Slappy Wilson')"),
      insert("INSERT INTO users (name) VALUES ('Jumpy Jones')")
    ]

    select("SELECT * FROM users WHERE id IN ?", nil, ids) do |reader|
      # select already calls next once for us
      reader.next!.should == true
      reader.next!.should be_nil
    end
  end

  it "should return DB nulls as nil" do
    id = insert("INSERT INTO users (name) VALUES (NULL)")
    select("SELECT name from users WHERE name is null") do |reader|
      reader.values[0].should == nil
    end
  end

end
