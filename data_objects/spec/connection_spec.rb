require File.dirname(__FILE__) + '/spec_helper'

describe DataObjects::Connection do
  
  it "should return a new connection and add it to the available connections pool when released" do
    
    connection = DataObjects::Connection.new('sqlite3://do_rb.db')
    
    
    
  end

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