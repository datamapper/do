require File.dirname(__FILE__) + '/spec_helper'

describe DataObjects::Command do
  
  it "should define a standard API" do
    connection = DataObjects::Connection.new('mock://localhost')
    
    command = connection.create_command("SELECT * FROM example")

    command.should respond_to(:connection)
    
    # #to_s returns the command-text, ie: the SQL.
    command.should respond_to(:to_s)
    
    command.should respond_to(:set_types)
    
    command.should respond_to(:execute_non_query)
    command.should respond_to(:execute_reader)
    
    connection.close
  end
  
end