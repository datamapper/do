require File.dirname(__FILE__) + '/spec_helper'

describe "DataObjects::JDBC" do
  
  it "should expose the proper DataObjects classes" do
    DataObjects::const_get('JDBC').should_not be_nil
    DataObjects::JDBC::const_get('Connection').should_not be_nil
    DataObjects::JDBC::const_get('Result').should_not be_nil
    #DataObjects::JDBC::const_get('Transaction').should_not be_nil
    #DataObjects::JDBC::Types::CHAR.should == 1
    #DataObjects::JDBC::Types::VARCHAR.should == 12
    #DataObjects::JDBC::Connection
    #DataObjects::JDBC::const_get('Connection')
    #DataObjects::JDBC::const_get('Transaction')
    #DataObjects::JDBC.const_get('Connection').should be_nil
  end
  
  it "should raise error on bad connection string" 
  
  it "should connect successfully via TCP" 
  it "should connect successfully via the socket file"
  it "should return the current character set"
  it "should support changing the character set"
  
end
