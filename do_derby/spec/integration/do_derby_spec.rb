require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataObjects::Derby::Connection" do
  include DerbySpecHelpers

  it "should connect to the database" do
    @connection = DataObjects::Connection.new("jdbc:derby:testdb;create=true")
  end

  it "should be closeable" do
    @connection = DataObjects::Connection.new("jdbc:derby:testdb;create=true")
    lambda { @connection.dispose }.should_not raise_error
  end

end

describe "DataObjects::Derby::Command" do
  include DerbySpecHelpers

  before(:all) do
    setup_test_environment
  end

  it "should be able to create a command" do
    command = @connection.create_command("SELECT id, name FROM users")
    command.set_types [Integer, String]
    command.should be_kind_of(DataObjects::Derby::Command)
    command.instance_variable_get("@types").should == [Integer, String]
  end

  describe "#execute_non_query" do

    it "should raise an error when given a bad query" do
      command = @connection.create_command("INSER INTO table_which_doesnt_exist (id) VALUES (1)")
      lambda { command.execute_non_query }.should raise_error(DerbyError,
          /Syntax error: Encountered \"INSER\"/)

      command = @connection.create_command("INSERT INTO table_which_doesnt_exist (id) VALUES (1)")
      lambda { command.execute_non_query }.should raise_error(DerbyError,
          /Table\/View \'TABLE_WHICH_DOESNT_EXIST\' does not exist./)
    end

    it "should execute and return a Result" do
      command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')")
      result = command.execute_non_query
      result.should be_kind_of(DataObjects::Derby::Result)
    end

  end

  describe "#execute_reader" do

    it "should raise an error when given a bad query" do
      command = @connection.create_command("SELCT * FROM table_which_doesnt_exist")
      lambda { command.execute_reader }.should raise_error(DerbyError,
          /Syntax error: Encountered \"SELCT\"/)

      command = @connection.create_command("SELECT * FROM table_which_doesnt_exist")
      lambda { command.execute_reader }.should raise_error(DerbyError,
          /Table\/View \'TABLE_WHICH_DOESNT_EXIST\' does not exist./)
    end

    it "should execute and return a Reader" do
      command = @connection.create_command("SELECT * FROM invoices")
      reader = command.execute_reader
      reader.should be_kind_of(DataObjects::Derby::Reader)
      reader.close.should == true
    end

  end

end

describe "DataObjects::Derby::Result" do
  include DerbySpecHelpers

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

    # for Derby the newly generated ids are starting at 2?

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

describe "DataObjects::Derby::Reader" do
  include DerbySpecHelpers

  before(:all) do
    setup_test_environment
  end

  it "should raise an error when you pass too many or too few types for the expected result set" do
    lambda {
      select("SELECT name, fired_at FROM users", [String, DateTime, Integer])
      }.should raise_error(DerbyError, /Field-count mismatch. Expected 3 fields, but the query yielded 2/)
  end

  it "shouldn't raise an error when you pass NO types for the expected result set" do
    lambda { select("SELECT name, fired_at FROM users", nil) }.should_not raise_error(DerbyError)
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
    reader.field_count.should == 14
    reader.row_count.should == 1
    reader.close
  end

  it "should raise an exception if .values is called after reading all available rows" do
    pending "Derby has no way of limiting rows being returned"
    select("SELECT * FROM widgets") do |reader|
      # select already calls next once for us
      reader.next!
      reader.next!

      lambda { reader.values }.should raise_error(DerbyError)
    end
  end

  it "should fetch the proper number of rows" do
    ids = [
      insert("INSERT INTO users (name) VALUES ('Slappy Wilson')"),
      insert("INSERT INTO users (name) VALUES ('Jumpy Jones')"),
      insert("INSERT INTO users (name) VALUES ('John Jackson')")
    ]
                                            # do_jdbc rewrites "?" as "(?,?)"
                                            # to correspond to the JDBC API
    select("SELECT * FROM users WHERE id IN ?", nil, ids) do |reader|
      # select already calls next once for us
      reader.next!
      reader.next!.should == true
      reader.next!.should be_nil
    end
  end

  it "should contain tainted strings" do
    id = insert("INSERT INTO users (name) VALUES ('Cuppy Canes')")

    select("SELECT name FROM users WHERE id = ?", nil, id) do |reader|
      reader.values.first.should be_tainted
    end

  end

  it "should return DB nulls as nil" do
    id = insert("INSERT INTO users (name) VALUES (NULL)")
    select("SELECT name from users WHERE name is null") do |reader|
      reader.values[0].should == nil
    end
  end

  it "should not convert empty strings to null" do
    id = insert("INSERT INTO users (name) VALUES ('')")
    select("SELECT name FROM users WHERE id = ?", [String], id) do |reader|
      reader.values.first.should == ''
    end
  end

  describe "Date, Time, and DateTime" do

    it "should return nil when the time is 0" do
      id = insert("INSERT INTO users (name, fired_at) VALUES ('James', '1970-01-01-00.00.00.000000')")
      select("SELECT fired_at FROM users WHERE id = ?", [Time], id) do |reader|
        reader.values.last.should be_nil
      end
      exec("DELETE FROM users WHERE id = ?", id)
    end

    it "should return DateTimes using the current locale's Time Zone" do
      date = DateTime.now
      id = insert("INSERT INTO users (name, fired_at) VALUES (?, ?)", 'Sam', date)
      select("SELECT fired_at FROM users WHERE id = ?", [DateTime], id) do |reader|
        reader.values.last.to_s.should == date.to_s
      end
      exec("DELETE FROM users WHERE id = ?", id)
    end

    now = DateTime.now

    dates = [
      now.new_offset( (-11 * 3600).to_r / 86400), # GMT -11:00
      now.new_offset( (-9 * 3600 + 10 * 60).to_r / 86400), # GMT -9:10, contrived
      now.new_offset( (-8 * 3600).to_r / 86400), # GMT -08:00
      now.new_offset( (+3 * 3600).to_r / 86400), # GMT +03:00
      now.new_offset( (+5 * 3600 + 30 * 60).to_r / 86400)  # GMT +05:30 (New Delhi)
    ]

    dates.each do |date|
      it "should return #{date.to_s} offset to the current locale's Time Zone if they were inserted using a different timezone" do
        pending "We don't support non-local date input yet"

        dates.each do |date|
          id = insert("INSERT INTO users (name, fired_at) VALUES (?, ?)", 'Sam', date)

          select("SELECT fired_at FROM users WHERE id = ?", [DateTime], id) do |reader|
            reader.values.last.to_s.should == now.to_s
          end

          exec("DELETE FROM users WHERE id = ?", id)
        end
      end
    end

  end


  describe "executing a non-query" do
    it "should return a Result" do
      command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')")
      result = command.execute_non_query
      result.should be_kind_of(DataObjects::Derby::Result)
    end

    it "should be able to determine the affected_rows" do
      command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')")
      result = command.execute_non_query
      result.to_i.should == 1
    end

    it "should yield the last inserted id" do
      pending "Deleting table data does not reset auto-increment column to 1"
      connection.create_command("DELETE FROM invoices").execute_non_query

      result = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')").execute_non_query
      result.insert_id.should == 1

      result = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('3456')").execute_non_query
      result.insert_id.should == 2
    end

    it "should be able to determine the affected_rows" do
      [
        "DELETE FROM invoices",
        "INSERT INTO invoices (invoice_number) VALUES ('1234')",
        "INSERT INTO invoices (invoice_number) VALUES ('1234')"
      ].each { |q| @connection.create_command(q).execute_non_query }

      result = @connection.create_command("UPDATE invoices SET invoice_number = '3456'").execute_non_query
      result.to_i.should == 2
    end

    it "should raise an error when executing an invalid query" do
      command = @connection.create_command("UPDwhoopsATE invoices SET invoice_number = '3456'")

      lambda { command.execute_non_query }.should raise_error(Exception)
    end

    #it "should raise an error when inserting the wrong typed data" do
    #   command = @connection.create_command("UPDATE invoices SET invoice_number = ?")
    #   command.execute_non_query(1)
    #end

  end

end
