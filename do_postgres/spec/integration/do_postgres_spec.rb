require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

#
#
# Create a postgres db named do_test that accepts connections
# from localhost from the postgres user (without password) to enable this spec.
#
# You also need to allow passwordless access from localhost-
# locate the following line in your pg_hba.conf file:
#
#  # IPv4 local connections:
#  host    all         all         127.0.0.1/32          md5
#
# and replace 'md5' with 'trust' for these specs to work
#
#

describe "DataObjects::Postgres::Connection" do
  include PostgresSpecHelpers

  it "should connect to the db" do
    connection = DataObjects::Connection.new(DO_POSTGRES_SPEC_URI)
    connection.close
  end

  it "should be able to send queries asynchronously in parallel" do
    pending "Asynchronous queries behaving oddly in JRuby" if JRUBY
    threads = []

    start = Time.now
    4.times do |i|
      threads << Thread.new do
        connection = DataObjects::Connection.new(DO_POSTGRES_SPEC_URI)
        command = connection.create_command("SELECT pg_sleep(1)")
        result = command.execute_non_query
      end
    end

    threads.each{|t| t.join }
    finish = Time.now
    (finish - start).should < 2
  end

end

describe "DataObjects::Postgres::Command" do
  include PostgresSpecHelpers

  before :all do
    @connection = ensure_users_table_and_return_connection
  end

  after :all do
    @connection.close
  end

  it "should create a command" do
    @connection.create_command("CREATE TABLE users").should be_a_kind_of(DataObjects::Postgres::Command)
  end

  it "should set types" do
    command = @connection.create_command("SELECT id, name FROM users")
    command.set_types [Integer, String]
    # NOTE: should we really be testing for the presence of instance variables?
    command.instance_variable_get(JRUBY ? "@types" : "@field_types").should == [Integer, String]
  end

  it "should execute a non query" do
    command = @connection.create_command("INSERT INTO users (name) VALUES ('Test')")
    result = command.execute_non_query
    result.should be_a_kind_of(DataObjects::Postgres::Result)
  end

  it "should execute a reader" do
    command = @connection.create_command("SELECT * FROM users")
    reader = command.execute_reader
    reader.should be_a_kind_of(DataObjects::Postgres::Reader)
    reader.close.should == true
  end
end

describe "DataObjects::Postgres::Result" do
  include PostgresSpecHelpers

  before :all do
    @connection = ensure_users_table_and_return_connection
  end

  after :all do
    @connection.close
  end

  it "should raise errors on bad queries" do
    command = @connection.create_command("INSER INTO users (name) VALUES ('Test')")
    lambda { command.execute_non_query }.should raise_error
    command = @connection.create_command("INSERT INTO users (non_existant_field) VALUES ('Test')")
    lambda { command.execute_non_query }.should raise_error
  end

  it "should not have an insert_id without RETURNING" do
    command = @connection.create_command("INSERT INTO users (name) VALUES ('Test')")
    result = command.execute_non_query
    result.insert_id.should == 0;
    result.to_i.should == 1;
  end

  it "should have an insert_id when RETURNING" do
    command = @connection.create_command("INSERT INTO users (name) VALUES ('Test') RETURNING id")
    result = command.execute_non_query
    result.insert_id.should_not == 0;
    result.to_i.should == 1;
  end
end

describe "DataObjects::Postgres::Reader" do
  include PostgresSpecHelpers

  before :all do
    @connection = ensure_users_table_and_return_connection
    @connection.create_command("INSERT INTO users (name) VALUES ('Test')").execute_non_query
    @connection.create_command("INSERT INTO users (name) VALUES ('Test')").execute_non_query
    @connection.create_command("INSERT INTO users (name) VALUES ('Test')").execute_non_query
  end

  it "should raise errors on bad queries" do
    command = @connection.create_command("SELT * FROM users")
    lambda { command.execute_reader }.should raise_error
    command = @connection.create_command("SELECT * FROM non_existant_table")
    lambda { command.execute_reader }.should raise_error
  end

  it "should open and close a reader with given types of columns" do
    command = @connection.create_command("SELECT id, name FROM users LIMIT 3")
    command.set_types [Integer, String ]
    reader = command.execute_reader
    reader.close.should == true
  end

  it "should open and close a reader without given types of columns" do
    command = @connection.create_command("SELECT * FROM users LIMIT 3")
    reader = command.execute_reader
    reader.close.should == true
  end

   it "should raise error on wrong number of columns calling set_types" do
     pending "C-extension does not raise an error on encountering wrong number of columns" unless JRUBY
     command = @connection.create_command("SELECT * FROM users LIMIT 3")
     command.set_types [Integer, String]
     lambda { reader = command.execute_reader }.should raise_error
  end

  it "should return proper number of rows and fields using row_count and field_count" do
    pending "do_jdbc doesn't return correctly row_count at the moment" if JRUBY
    command = @connection.create_command("SELECT id, name, registered, money FROM users ORDER BY id DESC LIMIT 3")
    reader = command.execute_reader
    reader.field_count.should == 4
    reader.row_count.should == 3
    reader.close
  end

  it "should typecast a value from the postgres type" do
    command = @connection.create_command("SELECT id, name, registered, money FROM users ORDER BY id DESC LIMIT 3")
    reader = command.execute_reader
    while ( reader.next!)
      reader.values[0].should be_a_kind_of(Integer)
      reader.values[1].should be_a_kind_of(String)
      reader.values[2].should == false
      reader.values[3].should == 1908.56
    end
    reader.close
  end

  it "should typecast from set_types" do
    command = @connection.create_command("SELECT id, name FROM users ORDER BY id LIMIT 1")
    command.set_types [Integer, String]
    reader = command.execute_reader
    reader.next!
    reader.values[0].should be_a_kind_of(Integer)
    reader.values[1].should be_a_kind_of(String)
    reader.close
  end

  it "should handle a null value" do
    id = insert("INSERT INTO users (name) VALUES (NULL)")
    select("SELECT name from users WHERE name is null") do |reader|
      reader.values[0].should == nil
    end
  end

  it "should return nil when the time is 0" do
    pending "We need to introduce something like Proxy for typeasting where each SQL type will have _rules_ of casting" if JRUBY
    pending "Fix zero representation of Time in PostgreSQL" unless JRUBY
    id = insert("INSERT INTO users (name, fired_at) VALUES ('James', '0000-00-00')")
    select("SELECT fired_at FROM users WHERE id = ?", [Time], id) do |reader|
      reader.values.last.should be_nil
    end
    exec("DELETE FROM users WHERE id = ?", id)
  end

  it "should not convert empty strings to null" do
    id = insert("INSERT INTO users (name) VALUES ('')")
    select("SELECT name FROM users WHERE id = ?", [String], id) do |reader|
      reader.values.first.should == ''
    end
  end

  it "should typecast a date field" do
    command = @connection.create_command("SELECT created_on FROM users WHERE created_on is not null LIMIT 1")
    reader = command.execute_reader
    reader.next!
    # do_jdbc currently returning Time
    reader.values[0].should be_a_kind_of(Date)
  end

  it "should typecast a BigDecimal field" do
    money_in_the_bank = BigDecimal.new('1.29')

    id = insert("INSERT INTO users (name, money) VALUES (?, ?)", "MC Hammer", money_in_the_bank)
    select("SELECT money FROM users WHERE id = ?", [BigDecimal], id) do |reader|
      reader.values.first.should == money_in_the_bank
    end
  end

  it "should return DateTimes using the current locale's Time Zone" do
    date = DateTime.now
    id = insert("INSERT INTO users (name, created_at) VALUES (?, ?)", 'Sam', date)
    select("SELECT created_at FROM users WHERE id = ?", [DateTime], id) do |reader|
      reader.values.last.to_s.should == date.to_s
    end
    exec("DELETE FROM users WHERE id = ?", id)
  end

  it "should typecast a timestamp field" do
    command = @connection.create_command("SELECT created_at FROM users WHERE created_at is not null LIMIT 1")
    reader = command.execute_reader
    reader.next!
    reader.values[0].should be_a_kind_of(DateTime)

    command = @connection.create_command("SELECT created_at::date as date FROM users WHERE created_at is not null LIMIT 1")
    reader = command.execute_reader
    reader.next!
    reader.values[0].should be_a_kind_of(Date)

  end

  it "should work on a join" do

    user = @connection.create_command("SELECT * FROM users WHERE id = 1").execute_reader
    user.next!

    @connection.create_command("INSERT INTO companies (name) VALUES ('ELEC')").execute_non_query
    reader = @connection.create_command(<<-EOF).execute_reader
      SELECT u.* FROM users AS u
      LEFT JOIN companies AS c
        ON u.company_id=c.id
      WHERE c.name='ELEC'
    EOF
    reader.next!
    reader.values.should == user.values
  end

  it "should not typecast a time field" do
    command = @connection.create_command("SELECT born_at FROM users LIMIT 1")
    reader = command.execute_reader
    reader.next!
    reader.values[0].should be_a_kind_of(String)
  end

  it "should typecast a timestamp field without time zone" do
    command = @connection.create_command("SELECT created_at FROM users LIMIT 1")
    reader = command.execute_reader
    reader.next!
    reader.values[0].should be_a_kind_of(DateTime)
  end

  it "should typecast a timestamp field with time zone" do
    command = @connection.create_command("SELECT fired_at FROM users LIMIT 1")
    reader = command.execute_reader
    reader.next!
    reader.values[0].should be_a_kind_of(DateTime)
  end

  it "should typecast a numeric field to a big decimal" do
    command = @connection.create_command("SELECT amount FROM users LIMIT 1")
    reader = command.execute_reader
    reader.next!
    reader.values[0].should be_a_kind_of(BigDecimal)
  end

  it "should return the current character set" do
    connection = DataObjects::Connection.new("postgres://#{POSTGRES.user}:#{POSTGRES.pass}@#{POSTGRES.hostname}:#{POSTGRES.port}/#{POSTGRES.database}")
    connection.character_set.should == "utf8"
    connection.close
  end

  it "should support changing the character set" do
    pending "JDBC API does not provide an easy way to get the current character set" if JRUBY
    # current character set can be retrieved with the following query:
    # "SHOW VARIABLES LIKE character_set_database"

    connection = DataObjects::Connection.new("postgres://#{POSTGRES.user}:#{POSTGRES.pass}@#{POSTGRES.hostname}:#{POSTGRES.port}/#{POSTGRES.database}?charset=latin1")
                 # N.B. query parameter after forward slash causes problems with JDBC
    connection.character_set.should == "latin1"
    connection.close

    connection = DataObjects::Connection.new("postgres://#{POSTGRES.user}:#{POSTGRES.pass}@#{POSTGRES.hostname}:#{POSTGRES.port}/#{POSTGRES.database}?charset=utf8")
    connection.character_set.should == "utf8"
    connection.close
  end

end
