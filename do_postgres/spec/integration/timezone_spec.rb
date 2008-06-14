require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataObjects::Postgres::Reader" do
  include PostgresSpecHelpers

  before :all do
    @connection = ensure_users_table_and_return_connection
    Time.now.to_s.match(/\w{3} \w{3} \d{2} \d{2}:\d{2}:\d{2} ([-+]\d{2})(\d{2})/)
    @connection.create_command("SET SESSION TIME ZONE INTERVAL '#{$1}:#{$2}' HOUR TO MINUTE").execute_non_query
    @connection.create_command("INSERT INTO users (name) VALUES ('Test')").execute_non_query
    @connection.create_command("INSERT INTO users (name) VALUES ('Test')").execute_non_query
    @connection.create_command("INSERT INTO users (name) VALUES ('Test')").execute_non_query
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

end
