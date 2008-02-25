require File.dirname(__FILE__) + '/spec_helper'

describe DataObjects::Reader do
  
  it "should define a standard API" do
    connection = DataObjects::Connection.new('mock://localhost')
    
    command = connection.create_command("SELECT * FROM example")
    
    reader = command.execute_reader
        
    result.should respond_to(:close)
    result.should respond_to(:eof?)
    result.should respond_to(:next!)
    result.should respond_to(:values)
    result.should respond_to(:fields)
  end
  
end