require File.dirname(__FILE__) + '/spec_helper'

describe DataObjects::Connection do
  
  it "should define a standard API" do
    DataObjects::Connection.should respond_to(:new)
    DataObjects::Connection.should respond_to(:aquire)
    DataObjects::Connection.should respond_to(:release)
    
    connection = DataObjects::Connection.new('mock://localhost')
    
    connection.should respond_to(:close)
    
    connection.should respond_to(:to_s)
    connection.should respond_to(:begin_transaction)
    connection.should respond_to(:real_close)
    connection.should respond_to(:create_command)
    
    connection.close
  end
  
end