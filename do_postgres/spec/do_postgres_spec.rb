require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

#
#
# Create a postgres db named do_test that accepts connections
# from localhost from your current user (without password) to enable this spec.
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
    connection = DataObjects::Connection.new("postgres://localhost/do_test")
  end
end

describe "DataObjects::Postgres::Command" do
  include PostgresSpecHelpers

  before :all do
    @connection = ensure_users_table_and_return_connection
  end

  it "should create a command" do
    @connection.create_command("CREATE TABLE users").should be_a_kind_of(DataObjects::Postgres::Command)
  end

  it "should set types" do
    command = @connection.create_command("SELECT id, name FROM users")
    command.set_types [Integer, String]
    command.instance_variable_get("@field_types").should == [Integer, String]
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

  it "should open and close a reader" do
    command = @connection.create_command("SELECT * FROM users LIMIT 3")
    command.set_types [Integer, String]
    reader = command.execute_reader
    reader.close
  end

  it "should typecast a value from the postgres type" do
    command = @connection.create_command("SELECT id, name, registered, money FROM users ORDER BY id DESC LIMIT 3")
    reader = command.execute_reader
    reader.send(:instance_variable_get, "@field_count").should == 4
    reader.send(:instance_variable_get, "@row_count").should == 3
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
    reader.values[0].should be_a_kind_of(Date)
  end

  it "should typecast a BigDecimal field" do
    money_in_the_bank = BigDecimal.new('1.29')

    id = insert("INSERT INTO users (name, money) VALUES (?, ?)", "MC Hammer", money_in_the_bank)
    select("SELECT money FROM users WHERE id = ?", [BigDecimal], id) do |reader|
      reader.values.first.should == money_in_the_bank
    end
  end

  it "should typecast a timestamp field" do
    command = @connection.create_command("SELECT created_at FROM users WHERE created_at is not null LIMIT 1")
    reader = command.execute_reader
    reader.next!
    dt = reader.values[0]
    reader.values[0].should be_a_kind_of(DateTime)
    
    command = @connection.create_command("SELECT created_at::date as date FROM users WHERE created_at is not null LIMIT 1")
    reader = command.execute_reader
    reader.next!
    reader.values[0].should be_a_kind_of(Date)
    
  end
  
  it "should work on a join" do
    @connection.create_command("INSERT INTO companies (name) VALUES ('ELEC')").execute_non_query
    reader = @connection.create_command(<<-EOF).execute_reader
      SELECT u.*, c.name FROM users AS u
      LEFT JOIN companies AS c
        ON u.company_id=c.id
      WHERE c.name='ELEC'
    EOF
    reader.next!
    reader.values.last.should == "ELEC"
    reader.values.first.should == 1
  end

  it "should return DateTimes using the current locale's Time Zone for TIMESTAMP WITHOUT TIME ZONE fields" do
    date = DateTime.now
    id = insert("INSERT INTO users (name, created_at) VALUES (?, ?)", 'Sam', date)
    select("SELECT created_at FROM users WHERE id = ?", [DateTime], id) do |reader|
      reader.values.last.to_s.should == date.to_s
    end
    exec("DELETE FROM users WHERE id = ?", id)
  end

  it "should return DateTimes using the current locale's Time Zone TIMESTAMP WITH TIME ZONE fields" do
    date = DateTime.now
    id = insert("INSERT INTO users (name, fired_at) VALUES (?, ?)", 'Sam', date)
    select("SELECT fired_at FROM users WHERE id = ?", [DateTime], id) do |reader|
      reader.values.last.to_s.should == date.to_s
    end
    exec("DELETE FROM users WHERE id = ?", id)
  end

  it "should return DateTimes using the current locale's Time Zone if they were inserted using a different timezone" do
    now = DateTime.now
    dates = [
      now,
      now.new_offset( (-11 * 3600).to_r / 86400), # GMT -11:00
      now.new_offset( (-9 * 3600 + 10 * 60).to_r / 86400), # GMT -9:10
      now.new_offset( (-8 * 3600).to_r / 86400), # GMT -08:00
      now.new_offset( (+3 * 3600).to_r / 86400), # GMT +03:00
      now.new_offset( (+5 * 3600 + 30 * 60).to_r / 86400)  # GMT +05:30 (New Delhi)
    ]

    dates.each do |date|
      id = insert("INSERT INTO users (name, fired_at) VALUES (?, ?)", 'Sam', date)

      select("SELECT name, fired_at FROM users WHERE id = ?", [String, DateTime], id) do |reader|
        reader.fields.should == ["name", "fired_at"]
        reader.values.last.to_s.should == now.to_s
      end

      exec("DELETE FROM users WHERE id = ?", id)
    end
  end

  it "should typecast a time field" do
    pending "Postgres time fields do not store date information, so the Time class doesn't work"
    command = @connection.create_command("SELECT born_at FROM users LIMIT 1")
    reader = command.execute_reader
    reader.next!
    reader.values[0].should be_a_kind_of(Time)
  end
end
