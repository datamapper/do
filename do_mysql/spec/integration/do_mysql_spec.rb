require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe DataObjects::Mysql do
  include MysqlSpecHelpers

  before :each do
    setup_test_environment
  end

  after :each do
    teardown_test_environment
  end

  it "should expose the proper DataObjects classes" do
    DataObjects::Mysql.const_get('Connection').should_not be_nil
    DataObjects::Mysql.const_get('Command').should_not be_nil
    DataObjects::Mysql.const_get('Result').should_not be_nil
    DataObjects::Mysql.const_get('Reader').should_not be_nil
  end

  it "should connect successfully via TCP" do
    pending "Problems parsing regular connection URIs vs. JDBC URLs" if JRUBY
    connection = DataObjects::Connection.new("mysql://root@127.0.0.1:3306/do_mysql_test")
    connection.should_not be_using_socket
    connection.close
  end

  it "should be able to send querues asynchronuously in parallel" do
    threads = []

    start = Time.now
    4.times do |i|
      threads << Thread.new do
        connection = DataObjects::Connection.new("mysql://root@127.0.0.1:3306/do_mysql_test")
        command = connection.create_command("SELECT sleep(1)")
        result = command.execute_non_query
      end
    end

    threads.each{|t| t.join }
    finish = Time.now
    (finish - start).should < 2
  end

#
#  I comment this out partly to raise the issue for discussion. Socket files are afaik not supported under windows. Does this
#  mean that we should test for it on unix boxes but not on windows boxes? Or does it mean that it should not be speced at all?
#  It's not really a requirement, since all architectures that support MySQL also supports TCP connectsion, ne?
#
#  it "should connect successfully via the socket file" do
#    @connection = DataObjects::Mysql::Connection.new("mysql://root@localhost:3306/do_mysql_test/?socket=#{SOCKET_PATH}")
#    @connection.should be_using_socket
#  end

  it "should return the current character set" do
    pending "Problems parsing regular connection URIs vs. JDBC URLs" if JRUBY
    connection = DataObjects::Connection.new("mysql://root@localhost:3306/do_mysql_test")
    connection.character_set.should == "utf8"
    connection.close
  end

  it "should support changing the character set" do
    pending "Problems parsing regular connection URIs vs. JDBC URLs" if JRUBY
    connection = DataObjects::Connection.new("mysql://root@localhost:3306/do_mysql_test/?charset=latin1")
    connection.character_set.should == "latin1"
    connection.close

    connection = DataObjects::Connection.new("mysql://root@localhost:3306/do_mysql_test/?charset=utf8")
    connection.character_set.should == "utf8"
    connection.close
  end

  it "should raise an error when opened with an invalid server uri" do
    pending "Problems parsing regular connection URIs vs. JDBC URLs" if JRUBY
    def connecting_with(uri)
      lambda { DataObjects::Connection.new(uri) }
    end

    # Missing database name
    connecting_with("mysql://root@localhost:3306/").should raise_error(MysqlError)

    # Wrong port
    connecting_with("mysql://root@localhost:666/").should raise_error(MysqlError)

    # Bad Username
    connecting_with("mysql://baduser@localhost:3306/").should raise_error(MysqlError)

    # Bad Password
    connecting_with("mysql://root:wrongpassword@localhost:3306/").should raise_error(MysqlError)

    # Bad Database Name
    connecting_with("mysql://root@localhost:3306/bad_database").should raise_error(MysqlError)

    #
    # Again, should socket even be speced if we don't support it across all platforms?
    #
    # Invalid Socket Path
    #connecting_with("mysql://root@localhost:3306/do_mysql_test/?socket=/invalid/path/mysql.sock").should raise_error(MysqlError)
  end
end

describe DataObjects::Mysql::Connection do
  include MysqlSpecHelpers

  before :each do
    setup_test_environment
  end

  after :each do
    teardown_test_environment
  end

  it "should raise an error when attempting to execute a bad query" do
    lambda { @connection.create_command("INSERT INTO non_existant_table (tester) VALUES (1)").execute_non_query }.should raise_error(MysqlError)
  end

  it "should raise an error when executing a bad reader" do
    lambda { @connection.create_command("SELECT * FROM non_existant_table").execute_reader }.should raise_error(MysqlError)
  end

  it "should close the connection when executing a bad query" do
    lambda { @connection.create_command("INSERT INTO non_exista (tester) VALUES (1)").execute_non_query }.should raise_error(MysqlError)
    @connection.instance_variable_get(:@connection).should == nil
  end

  it "should flush the pool when executing a bad query" do
    pool = @connection.instance_variable_get(:@__pool)
    lambda { @connection.create_command("INSERT INTO non_exista (tester) VALUES (1)").execute_non_query }.should raise_error(MysqlError)
    Extlib::Pooling.pools.detect { |p| p == pool }.instance_variable_get(:@available).size.should == 0
  end

  it "should delete itself from the pool" do
    pool = @connection.instance_variable_get(:@__pool)
    count = pool.size
    lambda { @connection.create_command("INSERT INTO non_exista (tester) VALUES (1)").execute_non_query }.should raise_error(MysqlError)
    Extlib::Pooling.pools.detect { |p| p == pool }.size.should == count-1
  end

  it "should not raise an error error executing a non query on a closed connection" do
    lambda { @connection.create_command("INSERT INTO non_existant_table (tester) VALUES (1)").execute_non_query }.should raise_error(MysqlError)
    lambda { @connection.create_command("INSERT INTO non_existant_table (tester) VALUES (1)").execute_non_query }.should raise_error(MysqlError, "This connection has already been closed.")
  end

  it "should not raise an error executing a reader on a closed connection" do
    lambda { @connection.create_command("SELECT * FROM non_existant_table").execute_reader }.should raise_error(MysqlError)
    lambda { @connection.create_command("SELECT * FROM non_existant_table").execute_reader }.should raise_error(MysqlError, "This connection has already been closed.")
  end

end

describe DataObjects::Mysql::Reader do
  include MysqlSpecHelpers

  before :each do
    setup_test_environment
  end

  after :each do
    teardown_test_environment
  end

  it "should raise an error when you pass too many or too few types for the expected result set" do
    lambda { select("SELECT name, fired_at FROM users", [String, DateTime, Integer]) }.should raise_error(MysqlError)
  end

  it "shouldn't raise an error when you pass NO types for the expected result set" do
    lambda { select("SELECT name, fired_at FROM users", nil) }.should_not raise_error(MysqlError)
  end

  it "should return the proper number of fields" do
    id = insert("INSERT INTO users (name) VALUES ('Billy Bob')")
    select("SELECT id, name, fired_at FROM users WHERE id = ?", nil, id) do |reader|
      reader.fields.size.should == 3
    end
  end

  it "should raise an exception if .values is called after reading all available rows" do
    select("SELECT * FROM widgets LIMIT 2") do |reader|
      # select already calls next once for us
      reader.next!
      reader.next!

      lambda { reader.values }.should raise_error(MysqlError)
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
      id = insert("INSERT INTO users (name, fired_at) VALUES ('James', 0);")
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
      result.should be_kind_of(DataObjects::Mysql::Result)
    end

    it "should be able to determine the affected_rows" do
      command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')")
      result = command.execute_non_query
      result.to_i.should == 1
    end

    it "should yield the last inserted id" do
      @connection.create_command("TRUNCATE TABLE invoices").execute_non_query

      result = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')").execute_non_query
      result.insert_id.should == 1

      result = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('3456')").execute_non_query
      result.insert_id.should == 2
    end

    it "should be able to determine the affected_rows" do
      [
        "TRUNCATE TABLE invoices",
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

    # it "should raise an error when inserting the wrong typed data" do
    #   command = @connection.create_command("UPDATE invoices SET invoice_number = ?")
    #   command.execute_non_query(1)
    # end

  end

end
