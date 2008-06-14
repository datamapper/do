require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

require 'date'

describe DataObjects::Mysql::Command do

  before(:each) do
    @connection = if JRUBY
      DataObjects::Mysql::Connection.new(DO_MYSQL_SPEC_JDBC_URI)
    else
      DataObjects::Mysql::Connection.new(DO_MYSQL_SPEC_URI)
    end
  end

  it "should escape strings properly" do
    command = @connection.create_command("SELECT * FROM widgets WHERE name = ?")
    command.quote_string("Willy O'Hare & Johnny O'Toole").should == "'Willy O\\'Hare & Johnny O\\'Toole'".dup
    command.quote_string("The\\Backslasher\\Rises\\Again").should == "'The\\\\Backslasher\\\\Rises\\\\Again'"
    command.quote_string("Scott \"The Rage\" Bauer").should == "'Scott \\\"The Rage\\\" Bauer'"
  end

  it "should quote DateTime's properly" do
    command = @connection.create_command("SELECT * FROM widgets WHERE release_datetime >= ?")
    dt = DateTime.now
    command.quote_datetime(dt).should == "'#{dt.strftime('%Y-%m-%d %H:%M:%S')}'"
  end

  it "should quote Time's properly" do
    command = @connection.create_command("SELECT * FROM widgets WHERE release_timestamp >= ?")
    dt = Time.now
    command.quote_time(dt).should == "'#{dt.strftime('%Y-%m-%d %H:%M:%S')}'"
  end

  it "should quote Date's properly" do
    command = @connection.create_command("SELECT * FROM widgets WHERE release_date >= ?")
    dt = Date.today
    command.quote_date(dt).should == "'#{dt.strftime('%Y-%m-%d')}'"
  end

end
