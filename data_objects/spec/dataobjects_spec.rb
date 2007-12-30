require File.dirname(__FILE__) + '/spec_helper'

describe "Connectable", :shared => true do
  before :each do
    @c = $adapter_module::Connection.new($connection_string)
    @c.open
  end
  
  after :each do
    @c.close
  end
end

describe "DO::Connection" do
  it_should_behave_like "Connectable"
  
  it "should be able to be opened" do
    @c.should be_is_a($adapter_module::Connection)
    @c.state.should == 0
  end

  it "should be able to create a related command" do
    @c.open
    cmd = @c.create_command("select * from table1")
    cmd.connection.should == @c
  end
  
end

describe "DO::Command" do
  it_should_behave_like "Connectable"

  def delete_3
    cmd = @c.create_command("DELETE from table1 where id=3")
    cmd.execute_non_query.should == 1    
  end

  it "should be able to be executed if it's a select" do
    cmd = @c.create_command("select * from table1")
    r = cmd.execute_reader
    r.has_rows.should be_true
    r.close
  end
  
  it "should be able to be executed if it's not a select" do
    cmd = @c.create_command("INSERT into table1(#{$escaped_columns}) VALUES(3, NULL, NULL, NULL, NULL)")
    cmd.execute_non_query.should == 1
    delete_3
  end
  
  it "should throw an error if a select is passed to execute_non_query" do
    cmd = @c.create_command("SELECT * from table1")
    lambda { cmd.execute_non_query }.should raise_error(DataObject::QueryError)
  end
  
  it "should immediately close the reader and populate records_affected if a modification is passed to execute_reader" do
    if $adapter_module.to_s == "DataObject::Postgres"
      cmd = @c.create_command("INSERT into table1(#{$escaped_columns}) VALUES(3, NULL, now(), false, now())")      
    else
      cmd = @c.create_command("INSERT into table1(#{$escaped_columns}) VALUES(3, NULL, CURRENT_TIME, 0, CURRENT_DATE)")
    end
    r = cmd.execute_reader
    r.records_affected.should == 1
    lambda { r.name(0) }.should raise_error(DataObject::ReaderClosed)
    delete_3
  end
  
end

describe "DO::Reader" do
  
  before :each do
    @c = $adapter_module::Connection.new($connection_string)
    @c.open
    cmd = @c.create_command("select * from table1")
    @r = cmd.execute_reader    
  end
  
  after :each do
    @c.close
  end
  
  it "should be able to get the field count" do
    @r.field_count.should == 5
  end
  
  it "should be able to get field names" do
    @r.name(0).should == "id"
    @r.name(1).should == "int"
    @r.name(2).should == "time"
    @r.name(3).should == "bool"
    @r.name(4).should == "date"
    @r.name(5).should == nil
  end
  
  it "should be able to get field indexes" do
    @r.get_index("id").should == 0
    @r.get_index("int").should == 1
    @r.get_index("time").should == 2
    @r.get_index("bool").should == 3
    @r.get_index("date").should == 4
    @r.get_index("foo").should == nil
  end

  it "should be able to determine whether a particular field is null" do
    @r.null?(0).should == false
    @r.null?(1).should == true
  end
  
  it "should be able to get a typecasted version of a particular field" do
    case $adapter_module.to_s
    when "DataObject::Sqlite3"
      @r.item(0).should == 1
      @r.item(1).should == nil
      @r.item(2).class.should == String
      @r.item(3).should == 0
      @r.item(4).class.should == String
    when "DataObject::Mysql"
      @r.item(0).should == 1
      @r.item(1).should == nil
      @r.item(2).class.should == DateTime
      @r.item(3).should == false
      @r.item(4).class.should == Date
    end
  end
  
  it "should be able to get to the next row" do
    @r.next.should == true
    @r.item(0).should == 2
  end
  
  it "should return nil and close the reader when the cursor reaches the end" do
    @r.next
    @r.next.should == nil
    lambda { @r.name(0) }.should raise_error(DataObject::ReaderClosed)
  end
  
end